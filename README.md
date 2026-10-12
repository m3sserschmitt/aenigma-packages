## Aenigma APT Repository
 
A Debian/Ubuntu APT repository for installing packages via `apt`.
 
### Setup
 
```bash
curl -fsSL https://packages.aenigma.ro/aenigma.gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/packages.aenigma.ro.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/packages.aenigma.ro.gpg] https://packages.aenigma.ro stable main" | sudo tee /etc/apt/sources.list.d/packages.aenigma.ro.list
sudo apt-get update
sudo apt-get install aenigma
```

### Contact

You can report errors or suggest improvements at [contact@aenigma.ro](mailto:contact@aenigma.ro)
