## Aenigma APT Repository
 
A Debian/Ubuntu APT repository for installing packages via `apt`.
 
### Setup
 
```bash
curl -fsSL https://packages.aenigma.ro/aenigma.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/packages.aenigma.ro.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/packages.aenigma.ro.gpg] https://packages.aenigma.ro stable main" | tee /etc/apt/sources.list.d/packages.aenigma.ro.list

sudo apt update
```

### Contact

You can report errors or suggest improvements at [contact@aenigma.ro](mailto:contact@aenigma.ro)
