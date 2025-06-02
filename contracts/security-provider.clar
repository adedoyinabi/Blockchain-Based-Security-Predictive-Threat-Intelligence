;; Security Provider Verification Contract
;; Manages registration and verification of security providers

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))
(define-constant err-not-verified (err u103))

(define-map providers
  { provider: principal }
  {
    name: (string-ascii 50),
    reputation-score: uint,
    verified: bool,
    registration-block: uint
  }
)

(define-map provider-stats
  { provider: principal }
  {
    total-predictions: uint,
    accurate-predictions: uint,
    last-activity: uint
  }
)

(define-public (register-provider (name (string-ascii 50)))
  (let ((provider tx-sender))
    (asserts! (is-none (map-get? providers { provider: provider })) err-already-registered)
    (map-set providers
      { provider: provider }
      {
        name: name,
        reputation-score: u50,
        verified: false,
        registration-block: block-height
      }
    )
    (map-set provider-stats
      { provider: provider }
      {
        total-predictions: u0,
        accurate-predictions: u0,
        last-activity: block-height
      }
    )
    (ok provider)
  )
)

(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? providers { provider: provider })) err-not-found)
    (map-set providers
      { provider: provider }
      (merge (unwrap-panic (map-get? providers { provider: provider }))
        { verified: true }
      )
    )
    (ok true)
  )
)

(define-public (update-reputation (provider principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? providers { provider: provider })) err-not-found)
    (map-set providers
      { provider: provider }
      (merge (unwrap-panic (map-get? providers { provider: provider }))
        { reputation-score: new-score }
      )
    )
    (ok new-score)
  )
)

(define-read-only (get-provider (provider principal))
  (map-get? providers { provider: provider })
)

(define-read-only (get-provider-stats (provider principal))
  (map-get? provider-stats { provider: provider })
)

(define-read-only (is-verified-provider (provider principal))
  (match (map-get? providers { provider: provider })
    provider-data (get verified provider-data)
    false
  )
)
