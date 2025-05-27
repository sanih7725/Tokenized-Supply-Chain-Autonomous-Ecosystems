;; Ecosystem Coordination Contract
;; Manages autonomous supply networks

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-exists (err u202))
(define-constant err-unauthorized (err u203))

;; Network data structure
(define-map networks
  { network-id: uint }
  {
    coordinator: principal,
    network-name: (string-ascii 100),
    active-entities: uint,
    coordination-score: uint,
    created-block: uint
  }
)

;; Entity network membership
(define-map network-members
  { network-id: uint, entity-id: uint }
  {
    joined-block: uint,
    contribution-score: uint,
    active: bool
  }
)

(define-data-var next-network-id uint u1)

;; Create a new coordination network
(define-public (create-network (network-name (string-ascii 100)))
  (let ((network-id (var-get next-network-id)))
    (asserts! (is-none (map-get? networks { network-id: network-id })) err-already-exists)
    (map-set networks
      { network-id: network-id }
      {
        coordinator: tx-sender,
        network-name: network-name,
        active-entities: u0,
        coordination-score: u0,
        created-block: block-height
      }
    )
    (var-set next-network-id (+ network-id u1))
    (ok network-id)
  )
)

;; Join a network
(define-public (join-network (network-id uint) (entity-id uint))
  (let ((network (unwrap! (map-get? networks { network-id: network-id }) err-not-found)))
    (asserts! (is-none (map-get? network-members { network-id: network-id, entity-id: entity-id })) err-already-exists)
    (map-set network-members
      { network-id: network-id, entity-id: entity-id }
      {
        joined-block: block-height,
        contribution-score: u0,
        active: true
      }
    )
    (map-set networks
      { network-id: network-id }
      (merge network { active-entities: (+ (get active-entities network) u1) })
    )
    (ok true)
  )
)

;; Update coordination score
(define-public (update-coordination-score (network-id uint) (new-score uint))
  (let ((network (unwrap! (map-get? networks { network-id: network-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get coordinator network)) err-unauthorized)
    (map-set networks
      { network-id: network-id }
      (merge network { coordination-score: new-score })
    )
    (ok true)
  )
)

;; Get network details
(define-read-only (get-network (network-id uint))
  (map-get? networks { network-id: network-id })
)

;; Get member details
(define-read-only (get-member (network-id uint) (entity-id uint))
  (map-get? network-members { network-id: network-id, entity-id: entity-id })
)
