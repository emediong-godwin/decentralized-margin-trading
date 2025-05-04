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