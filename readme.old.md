## Hookie

#### Usage

To scan a specific GitHub repository for webhooks:

```bash
./find_webhook.sh --repo <username>/<repository>
```

Example:

```bash
./find_webhook.sh --repo jtmb/qbit-monitor
```

This will fetch the latest commits from the `jtmb/qbit-monitor` repository and search for any Discord webhooks.

#### Scan Random Repositories

To scan random repositories on GitHub:

```bash
./find_webhook.sh --random
```

This will continuously scan random repositories on GitHub and search for potential webhooks in their commits. You can adjust the interval between scans in the script.

#### Continuous Scanning

The script is designed to loop indefinitely when scanning random repositories. You can stop the script at any time using `Ctrl + C`.

#### Optional: Customize Scan Interval

You can customize the frequency of scanning by adjusting the `sleep` duration in the script. This will control how long the script waits between each scan.

#### Script Options

- `--repo <username>/<repository>`: Specify a GitHub repository to scan (e.g., `jtmb/qbit-monitor`).
- `--random`: Scan random repositories from GitHub.

#### Example Output

When a webhook is detected, the script will send a Discord notification, and you will see an output like:

```
⚠️ A Discord webhook was detected in a commit!
Webhook Detected
A potential Discord webhook was found in the repository jtmb/qbit-monitor.
Webhook URL
https://discord.com/api/webhooks/1192250006023983175/H3-tcdwMjKgC0LNM6W2DI3kWoYX-mYdIqR7xMUaXJxkUAM_QcATXvtzJb4wzO0OfPT6t
```

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
