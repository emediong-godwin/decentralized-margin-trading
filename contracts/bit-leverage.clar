;; Title: BitLeverage - Decentralized Margin Trading Protocol
;; 
;; Summary: A secure, compliant leverage trading platform for STX on the Stacks Layer 2,
;; with Bitcoin settlement guarantees and configurable leverage options up to 20x.
;;
;; Description: BitLeverage enables traders to open long and short positions with
;; leverage while maintaining strict risk management through automated liquidations.
;; The protocol implements standard margin trading functionality with proper
;; collateralization requirements and position management, operating within
;; Bitcoin's settlement assurances on Stacks Layer 2.

;; Constants and Traits

;; Error Codes - Clearly defined for better error handling and debugging
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-POSITION (err u103))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u104))
(define-constant ERR-ZERO-AMOUNT (err u105))
(define-constant ERR-MAX-LEVERAGE-EXCEEDED (err u106))
(define-constant ERR-POSITION-LIQUIDATED (err u107))
(define-constant ERR-INVALID-PRICE (err u108))

;; Protocol Parameters
(define-constant MIN-COLLATERAL-RATIO u150)  ;; 150% minimum collateral ratio
(define-constant MAX-LEVERAGE u20)           ;; Maximum 20x leverage

;; Position Types
(define-constant TYPE-LONG u1)  ;; Long position identifier
(define-constant TYPE-SHORT u2) ;; Short position identifier

;; Data Maps and Variables

;; User Balance Tracking
(define-map balances 
    principal 
    { stx-balance: uint }
)

;; Trading Positions Registry
(define-map positions 
    uint 
    { owner: principal,
      position-type: uint,
      size: uint,
      entry-price: uint,
      leverage: uint,
      collateral: uint,
      liquidation-price: uint,
      is-liquidated: bool }
)

;; Global State Variables
(define-data-var position-counter uint u0)
(define-data-var contract-owner principal tx-sender)
(define-data-var current-price uint u0)
(define-data-var contract-paused bool false)

;; Read-Only Functions

;; Retrieve user balance information
(define-read-only (get-balance (user principal))
    (default-to 
        { stx-balance: u0 }
        (map-get? balances user)
    )
)

;; Retrieve position details by ID
(define-read-only (get-position (position-id uint))
    (map-get? positions position-id)
)

;; Get current market price
(define-read-only (get-current-price)
    (ok (var-get current-price))
)

;; Get contract owner address
(define-read-only (get-contract-owner)
    (ok (var-get contract-owner))
)

;; Get total number of positions created
(define-read-only (get-position-count)
    (ok (var-get position-counter))
)

;; Check if contract is in paused state
(define-read-only (is-contract-paused)
    (ok (var-get contract-paused))
)

;; Calculate liquidation price based on position parameters
(define-read-only (calculate-liquidation-price 
    (entry-price uint) 
    (position-type uint) 
    (leverage uint))
    (begin
        ;; Validate inputs
        (asserts! (> entry-price u0) (err ERR-INVALID-PRICE))
        (asserts! (or (is-eq position-type TYPE-LONG) 
                     (is-eq position-type TYPE-SHORT)) 
                 (err ERR-INVALID-POSITION))
        (asserts! (and (> leverage u0) (<= leverage MAX-LEVERAGE)) 
                 (err ERR-MAX-LEVERAGE-EXCEEDED))
        
        (if (is-eq position-type TYPE-LONG)
            ;; Long position liquidation price
            (ok (/ (* entry-price (- u100 (/ u100 leverage))) u100))
            ;; Short position liquidation price
            (ok (/ (* entry-price (+ u100 (/ u100 leverage))) u100))
        )
    )
)

;; Check if a position is eligible for liquidation
(define-read-only (is-liquidatable (position-id uint))
    (let ((position (unwrap! (map-get? positions position-id) (err ERR-INVALID-POSITION)))
          (current-market-price (var-get current-price)))
        (if (get is-liquidated position)
            (ok true)
            (if (is-eq (get position-type position) TYPE-LONG)
                ;; Long position liquidation check
                (ok (<= current-market-price (get liquidation-price position)))
                ;; Short position liquidation check
                (ok (>= current-market-price (get liquidation-price position))))
        )
    )
)

;; Public Functions

;; Deposit collateral into the protocol
(define-public (deposit-collateral (amount uint))
    (begin
        ;; Validate amount
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        
        (let ((current-balance (get stx-balance (get-balance tx-sender))))
            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
            (ok (map-set balances 
                tx-sender 
                { stx-balance: (+ current-balance amount) }))
        )
    )
)

;; Withdraw collateral from the protocol
(define-public (withdraw-collateral (amount uint))
    (begin
        ;; Validate amount
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        
        (let ((current-balance (get stx-balance (get-balance tx-sender))))
            (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
            (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
            (ok (map-set balances 
                tx-sender 
                { stx-balance: (- current-balance amount) }))
        )
    )
)

;; Open a new leveraged trading position
(define-public (open-position 
    (position-type uint)
    (size uint)
    (leverage uint))
    (begin
        ;; Validate inputs
        (asserts! (> size u0) ERR-INVALID-AMOUNT)
        (asserts! (and (> leverage u0) (<= leverage MAX-LEVERAGE)) ERR-MAX-LEVERAGE-EXCEEDED)
        (asserts! (or (is-eq position-type TYPE-LONG) 
                     (is-eq position-type TYPE-SHORT)) ERR-INVALID-POSITION)
        (asserts! (> (var-get current-price) u0) ERR-INVALID-PRICE)
        
        (let 
            ((required-collateral (/ (* size (var-get current-price)) leverage))
             (current-balance (get stx-balance (get-balance tx-sender)))
             (position-id (+ (var-get position-counter) u1))
             (entry-price (var-get current-price)))

            ;; Check sufficient collateral
            (asserts! (>= current-balance required-collateral) ERR-INSUFFICIENT-COLLATERAL)

            ;; Calculate liquidation price
            (let ((liquidation-price (unwrap! (calculate-liquidation-price 
                                             entry-price 
                                             position-type 
                                             leverage) ERR-INVALID-POSITION)))

                ;; Create position
                (map-set positions position-id
                    { owner: tx-sender,
                      position-type: position-type,
                      size: size,
                      entry-price: entry-price,
                      leverage: leverage,
                      collateral: required-collateral,
                      liquidation-price: liquidation-price,
                      is-liquidated: false })

                ;; Update balance
                (map-set balances 
                    tx-sender 
                    { stx-balance: (- current-balance required-collateral) })

                ;; Increment position counter
                (var-set position-counter position-id)
                (ok position-id))
        )
    )
)

;; Close an existing position
(define-public (close-position (position-id uint))
    (let ((position (unwrap! (map-get? positions position-id) ERR-INVALID-POSITION)))
        ;; Verify owner
        (asserts! (is-eq (get owner position) tx-sender) ERR-UNAUTHORIZED)
        ;; Verify position is not liquidated
        (asserts! (not (get is-liquidated position)) ERR-POSITION-LIQUIDATED)
        
        ;; Check if position should be liquidated before closing
        (if (unwrap! (is-liquidatable position-id) ERR-INVALID-POSITION)
            ;; If liquidatable, liquidate instead of normal close
            (liquidate-position position-id)
            ;; Regular position closing
            (let ((pnl (calculate-pnl position)))
                ;; Return collateral + PnL (if positive)
                (try! (as-contract 
                       (stx-transfer? 
                        (+ (get collateral position) 
                           (if (> pnl u0) pnl u0)) 
                        tx-sender 
                        tx-sender)))

                ;; Delete position
                (map-delete positions position-id)
                (ok true))
        )
    )
)

;; Liquidate an under-collateralized position
(define-public (liquidate-position (position-id uint))
    (let ((position (unwrap! (map-get? positions position-id) ERR-INVALID-POSITION)))
        ;; Check if position is liquidatable
        (asserts! (unwrap! (is-liquidatable position-id) ERR-INVALID-POSITION) ERR-INVALID-POSITION)
        
        ;; Mark as liquidated and update position
        (map-set positions position-id
            (merge position { is-liquidated: true }))
        
        ;; Transfer liquidation fee to caller (5% of collateral)
        (let ((liquidation-fee (/ (* (get collateral position) u5) u100))
              (remaining-collateral (- (get collateral position) liquidation-fee)))
            
            ;; Pay liquidation fee to caller
            (try! (as-contract 
                   (stx-transfer? 
                    liquidation-fee 
                    tx-sender 
                    tx-sender)))
            
            ;; Return remaining collateral to position owner (if any)
            (if (> remaining-collateral u0)
                (try! (as-contract 
                    (stx-transfer? 
                    remaining-collateral 
                    (get owner position) 
                    tx-sender)))
                true)
                
            (ok true)
        )
    )
)