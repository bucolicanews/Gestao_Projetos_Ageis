# Homologação PagBank — Criar e Pagar Pedido com Cartão de Crédito

## Endpoint utilizado

`POST https://sandbox.api.pagseguro.com/orders`

---

## Request

```bash
curl --location --request POST 'https://sandbox.api.pagseguro.com/orders' \
--header 'Authorization: Bearer 5c4705bc-1463-46f6-831c-32ac5fd83aafda99a59b45719dd67e8a394e3453b26e2bfa-1f13-4909-a45b-f95b671ee5d4' \
--header 'Content-Type: application/json' \
--data-raw '{
  "reference_id": "ex-00001",
  "customer": {
    "name": "Jose da Silva",
    "email": "email@test.com",
    "tax_id": "12345678909",
    "phones": [
      {
        "country": "55",
        "area": "11",
        "number": "999999999",
        "type": "MOBILE"
      }
    ]
  },
  "items": [
    {
      "reference_id": "item-001",
      "name": "Assinatura Gestao Agil",
      "quantity": 1,
      "unit_amount": 4990
    }
  ],
  "notification_urls": [
    "https://meusite.com/notificacoes"
  ],
  "charges": [
    {
      "reference_id": "cobranca-001",
      "description": "Assinatura Gestao Agil",
      "amount": {
        "value": 4990,
        "currency": "BRL"
      },
      "payment_method": {
        "type": "CREDIT_CARD",
        "installments": 1,
        "capture": true,
        "card": {
          "encrypted": "V++53ir0qvoK/rUSzNjCqP8Hz9ZTa+HohR779n63CV+NvCeYj4J4lQevL4NKN7Di3BxKQGqfQW5cfS7/4rHw4w8URuOV/j/mGau2GXxkKQ6/szJ6BQr//C4e4XgfCHDwcONQhuPDHMdOB1C+4lzyBbsPJUZ/8TUQrxhMMiMFjwGeg62uf7cUqdFjp+Q5dqJXwhLgH3d1EoX+JKStBLqVzF0lW3gHtFOyfvFhuxxBgB0xrzTKfbTqnL5aSYBoGXRFM0gLodMm6knx7bW+syThxyQffnaigCwj2aNohsu+fuXII+3WnlgrHQxaBx3ChRuWKy+loV2L2USiGulp/bPEcg==",
          "store": false
        },
        "holder": {
          "name": "Jose da Silva",
          "tax_id": "12345678909"
        }
      }
    }
  ]
}'
```

---

## Response esperada (200 OK)

```json
{
  "id": "ORDE_XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "reference_id": "ex-00001",
  "created_at": "2026-05-28T20:00:00.000-03:00",
  "customer": {
    "name": "Jose da Silva",
    "email": "email@test.com",
    "tax_id": "12345678909",
    "phones": [
      {
        "country": "55",
        "area": "11",
        "number": "999999999",
        "type": "MOBILE"
      }
    ]
  },
  "items": [
    {
      "reference_id": "item-001",
      "name": "Assinatura Gestao Agil",
      "quantity": 1,
      "unit_amount": 4990
    }
  ],
  "charges": [
    {
      "id": "CHAR_XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
      "reference_id": "cobranca-001",
      "status": "PAID",
      "created_at": "2026-05-28T20:00:00.000-03:00",
      "paid_at": "2026-05-28T20:00:00.000-03:00",
      "description": "Assinatura Gestao Agil",
      "amount": {
        "value": 4990,
        "currency": "BRL",
        "summary": {
          "total": 4990,
          "paid": 4990,
          "refunded": 0
        }
      },
      "payment_response": {
        "code": "20000",
        "message": "SUCESSO",
        "reference": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
      },
      "payment_method": {
        "type": "CREDIT_CARD",
        "installments": 1,
        "capture": true,
        "card": {
          "brand": "MASTERCARD",
          "first_digits": "516748",
          "last_digits": "9999",
          "exp_month": "12",
          "exp_year": "2026",
          "holder": {
            "name": "Jose da Silva"
          }
        }
      }
    }
  ],
  "notification_urls": [
    "https://meusite.com/notificacoes"
  ]
}
```

---

## Campos verificados para confirmação de pagamento

| Campo | Valor esperado |
|-------|----------------|
| `charges[0].status` | `PAID` |
| `charges[0].payment_response.message` | `SUCESSO` |
| `charges[0].payment_response.code` | `20000` |
