NOTE: if you at any point you feel like it is taking too long and you can not make it work...
    **just comment out or remove PRISM parts from config and rerun tezbake upgrade**

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
3. gets latest packages and sets up prism 
   - `tezbake upgrade` or `sudo ami setup`
4. `tezbake start` or `sudo ami start`

