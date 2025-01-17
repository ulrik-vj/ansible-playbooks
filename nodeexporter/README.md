# How to setup the playbook for your environment

1. Add IPs to your servers in hosts file
2. If any IPs should be excluded and not checked during the updating, add them here
3. In the playbook add your Proxmox host to this line

```yml
when: inventory_hostname == "" # YOUR PROXMOX HOST HERE
```
4. Add your passwords in the file under group_vars --> my_vault.yml
5. Now encrypt with a strong password using ansible-vault so they are not in plaintext. 

Go into the group_vars dir and then:

```bash
ansible-vault encrypt my_vault.yml
```

6. Go back to the dir of the playbook and run it like so:

```bash
ansible-playbook -i hosts update_nodexporter_proxmox.yml --ask-vault-password
```
