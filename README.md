# Windows Troubleshooter Toolkit

A menu-driven PowerShell troubleshooting and repair toolkit for Windows 10 and Windows 11, covering help-desk, desktop support, and advanced infrastructure workflows.

**Current version:** 10.1  
**Author:** Dewald Pretorius

## Highlights

- Network, DNS, DHCP, VPN, proxy, firewall, and sharing diagnostics
- Windows repair, update, services, startup, storage, and performance tools
- Microsoft 365, OneDrive, Teams, Outlook, Exchange, and activation troubleshooting
- Entra ID, MFA, Conditional Access, BitLocker, Group Policy, and domain trust checks
- Printing, browser, profile migration, Autopilot, SCCM/MECM, WMI, Hyper-V, and hardware tools
- Audit logging and diagnostic report generation
- Optional integration with Microsoft Sysinternals and other external support utilities

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or a compatible PowerShell host
- Administrator privileges for repair operations
- Internet access for functions that download Microsoft or third-party utilities

## Run the toolkit

### Recommended

1. Download or clone this repository.
2. Double-click `Launch_Troubleshooter.bat`.
3. Approve the Windows UAC prompt.

### From PowerShell

Open PowerShell as Administrator, change to the project directory, and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\WindowsTroubleshooter.ps1
```

## Included files

- `WindowsTroubleshooter.ps1` — main toolkit
- `Launch_Troubleshooter.bat` — elevation and launch helper
- `Launch_Troubleshooter - Shortcut.lnk` — Windows shortcut supplied with the release

## Logs

The toolkit can write audit information to:

```text
C:\ProgramData\WinTroubleshooter\AuditLog.csv
```

## Safety notice

This toolkit performs administrative repair and configuration actions. Review the selected action before running it on production systems. Test potentially disruptive operations in a lab or on a non-critical device first. Some functions reset caches, services, networking components, policies, application registrations, or system configuration.

External utility functions may download software from Microsoft, GitHub, or vendor websites. Confirm the source and comply with your organisation's software policies before use.

## Support scope

The toolkit is intended for trained IT support personnel. It is provided without a warranty and should not replace backups, change control, or vendor-supported recovery procedures.

## License

No open-source licence has been assigned yet. All rights are reserved by the author unless a licence is added later.
