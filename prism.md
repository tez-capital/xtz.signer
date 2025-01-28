> **Note:** If at any point you feel like it is taking too long and you cannot make it work, you can simply comment out or remove the PRISM parts from the configuration and rerun `tezbake upgrade` or `sudo ami setup`.
> **Note2:** The `ami` commands have to be run separately for the node and the signer. `tezbake` does this for you automatically.

1. backup app.json from signer and node
    - `cp /bake-buddy/signer/app.json /bake-buddy/signer/app.json.backup`
    - `cp /bake-buddy/node/app.json /bake-buddy/node/app.json.backup`

2. edit signer and node app.json to include prism sections. Bellow configuration sets up default forwarding:
    - node rpc to signer side (for info checks)
    - signer endpoint to node side (for baking)
```json
// node
{
        "configuration": {
                ...
                "PRISM": {
                        "default_forwarder": true
                }
        },
        ...
}
```
```json
// signer
{
        "configuration": {
                ...
                "PRISM": {
                        // if you use remote node setup below remote address should match IP address from `REMOTE_NODE`
                        "remote": "<remote addr>:20080",
                        "default_forwarder": true
                }
        },
        ...
}
```
3. upgrade/setup to apply changes
   - `tezbake upgrade` or `sudo ami setup`
4. `tezbake start` or `sudo ami start`

