# What these two checks cover

1. **Cross-tenant READ (IDOR/BOLA):** a user from tenant T1 must not read resources from T2.
2. **Role-based UPDATE:** a regular user must not change protected fields (e.g., invoice status); an admin can.

## How to run

```bash
chmod +x tests/authz/authz.sh
tests/authz/authz.sh
```
