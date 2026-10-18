# Ashigaru Desktop

## Documentation

- [Ashigaru Desktop README](https://github.com/linkinparkrulz/ashigaru-desktop/blob/main/README.md) — features, release verification, and upstream usage notes.

## What you get on StartOS

- An **Ashigaru Desktop** interface that streams the full Ashigaru application to your browser, so Whirlpool can keep mixing while your own computer is off.
- Your wallets, settings and Tor state on a single backed-up volume.
- Ashigaru's own built-in Tor, exactly as on a desktop install.
- File upload and download from the desktop sidebar, for moving wallet exports and labels on and off the server.

## Getting set up

1. After install, StartOS posts a critical task **Set your desktop password**. Run it and save the generated `ashigaru` username and password in a password manager.
2. Start the service and open the **Ashigaru Desktop** interface. Sign in with the username and password from step 1 when your browser asks.
3. Ashigaru's welcome tour appears. Walk through it, then create or restore a wallet with **New / Restore**.
4. To use your own node, open **Settings → Server** in Ashigaru and choose **Private Electrum Server**. Enter the address of your Electrum server (electrs or Fulcrum) as StartOS shows it on that service's interfaces page. Its Tor (`.onion`) address works through Ashigaru's built-in Tor.

## Using Ashigaru Desktop

### Ashigaru Desktop interface

This is the same Ashigaru you would run on a computer, displayed in your browser. Use a browser window of at least 1100 × 800, since Ashigaru's main window is a fixed size. Leaving the browser tab, or closing it, does not stop Ashigaru: mixing carries on on the server. If you quit Ashigaru from its own menu, it starts again by itself after a couple of seconds.

### Actions

- **Set Desktop Password** — generates a new random password for the desktop sign-in and shows it. Run it if you lose the password or want to change it. Once a password exists, it asks you to confirm first, and Ashigaru restarts.

### Updates

Ashigaru's in-app updater is switched off on StartOS. New versions arrive as StartOS service updates.

## Limitations

- **x86_64 servers only.** Ashigaru publishes its Linux build for x86_64 only.
- **The backup contains your wallet.** Keep your seed phrase and passphrase backed up separately as well.
