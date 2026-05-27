import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.toml" },
        miniflare: {
          // Test-time env overrides — placeholders deterministas para los tests.
          bindings: {
            STRIPE_SECRET_KEY: "sk_test_dummy_for_tests",
            STRIPE_WEBHOOK_SECRET: "whsec_test_secret_for_vitest_only",
            ADMIN_TOKEN: "test-admin-token",
            STRIPE_PRICE_STANDARD: "price_standard_test",
            STRIPE_PRICE_PRO: "price_pro_test",
          },
          d1Databases: ["DB"],
          d1Persist: false,
        },
      },
    },
  },
});
