;; Entity Verification Contract
;; Validates autonomous supply chain systems

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Entity data structure
(define-map entities
  { entity-id: uint }
  {
    owner: principal,
    entity-type: (string-ascii 50),
    verification-status: bool,
    trust-score: uint,
    registration-block: uint
  }
)

(define-data-var next-entity-id uint u1)

;; Register a new autonomous entity
(define-public (register-entity (entity-type (string-ascii 50)))
  (let ((entity-id (var-get next-entity-id)))
    (asserts! (is-none (map-get? entities { entity-id: entity-id })) err-already-exists)
    (map-set entities
      { entity-id: entity-id }
      {
        owner: tx-sender,
        entity-type: entity-type,
        verification-status: false,
        trust-score: u50,
        registration-block: block-height
      }
    )
    (var-set next-entity-id (+ entity-id u1))
    (ok entity-id)
  )
)

;; Verify an entity (owner only)
(define-public (verify-entity (entity-id uint))
  (let ((entity (unwrap! (map-get? entities { entity-id: entity-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set entities
      { entity-id: entity-id }
      (merge entity { verification-status: true, trust-score: u100 })
    )
    (ok true)
  )
)

;; Update trust score
(define-public (update-trust-score (entity-id uint) (new-score uint))
  (let ((entity (unwrap! (map-get? entities { entity-id: entity-id }) err-not-found)))
    (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get owner entity))) err-unauthorized)
    (map-set entities
      { entity-id: entity-id }
      (merge entity { trust-score: new-score })
    )
    (ok true)
  )
)

;; Get entity details
(define-read-only (get-entity (entity-id uint))
  (map-get? entities { entity-id: entity-id })
)

;; Check if entity is verified
(define-read-only (is-entity-verified (entity-id uint))
  (match (map-get? entities { entity-id: entity-id })
    entity (get verification-status entity)
    false
  )
)
