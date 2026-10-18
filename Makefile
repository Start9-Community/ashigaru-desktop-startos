ARCHES := x86
# overrides to s9pk.mk must precede the include statement
JS_BUNDLE := rm -rf javascript && npx ncc build startos/index.ts -o javascript && chmod 755 javascript javascript/index.js

include node_modules/@start9labs/start-sdk/s9pk.mk
