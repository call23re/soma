## Soma
Soma is a compositional input library designed for Roblox games that use Entity-Component-System architecture. It is currently just a prototype, and it's missing several important features.

It supports:
- Complex input patterns via `actions`, which are composed of `inputs` and `bindings`.
- Input states composed with `pressed`, `pressing`, `released`, and `none`.
- Logical operators composed with `all` and `any`.
- Contexts
- Rebinding via `input::set`.
- Action cooldowns.
- Manually calling actions via `press` or `press_once`.
- Change tracking for bindings, inputs, and actions.

See the [example](/example) for more details.