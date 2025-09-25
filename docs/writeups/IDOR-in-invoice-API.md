# IDOR in invoice download endpoint

**Class**: Access control → IDOR (horizontal privilege escalation)  
**Asset**: Billing API — `GET /api/invoices/:id`  
**Test users**:

- userA (tenant T1), userB (tenant T2), admin (tenant T1)

## Summary (executive)

The invoice download endpoint does **not verify resource ownership** server-side. A standard user from tenant **T1** can retrieve invoices that belong to tenant **T2** by changing the path parameter `:id`. This exposes PII and financial data and violates tenant isolation.  
**Fix**: Enforce **server-side authorization** per request using `tenant_id`/`account_id`; return **403/404** on mismatch; add **AuthZ tests** in CI.

## Reproduction

1. Log in as **userA (T1)** and fetch your own invoice once to capture a valid request.
2. **Tamper** the URL from `/api/invoices/1001` (T1) to `/api/invoices/2002` (belongs to T2).
3. Observe the response:
   - **Vulnerable**: HTTP **200** + JSON/PDF of T2’s invoice.
   - **Expected**: HTTP **403/404**.

### PoC (cURL)

```bash
# Should be 403/404 if authorization is enforced
curl -i -H "Authorization: Bearer <USER_A_TOKEN>" \
  https://target.example.com/api/invoices/2002
