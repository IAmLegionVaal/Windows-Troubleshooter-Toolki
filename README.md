# Windows Troubleshooter Toolkit

![Version](https://img.shields.io/badge/version-10.1-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows)
![Status](https://img.shields.io/badge/status-active-success)

A menu-driven PowerShell troubleshooting and repair toolkit for Windows 10 and Windows 11, covering helpdesk, desktop support and advanced infrastructure workflows.

**Current version:** 10.1  
**Author:** Dewald Pretorius — L2 IT Support Engineer  
**Project type:** Primary all-in-one Windows support toolkit

## Purpose

This toolkit brings common Windows support workflows into one technician-friendly interface. It is designed to help support staff diagnose issues, collect useful evidence, apply guarded repairs and document results more consistently.

## Highlights

- Network, DNS, DHCP, VPN, proxy, firewall and sharing diagnostics
- Windows repair, update, services, startup, storage and performance tools
- Microsoft 365, OneDrive, Teams, Outlook, Exchange and activation troubleshooting
- Entra ID, MFA, Conditional Access, BitLocker, Group Policy and domain-trust checks
- Printing, browser, profile migration, Autopilot, SCCM/MECM, WMI, Hyper-V and hardware tools
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
4. Select the required diagnostic or repair workflow.
5. Review the generated logs and results before closing the toolkit.

### From PowerShell

Open PowerShell as Administrator, change to the project directory and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\WindowsTroubleshooter.ps1
```

## Included files

| File | Purpose |
|---|---|
| `WindowsTroubleshooter.ps1` | Main menu-driven troubleshooting and repair toolkit |
| `Launch_Troubleshooter.bat` | Elevation and launch helper |
| `Launch_Troubleshooter - Shortcut.lnk` | Windows shortcut supplied with the release |
| `CHANGELOG.md` | Current documented release information |
| `SECURITY.md` | Safe-use and vulnerability-reporting guidance |

## Logs

The toolkit can write audit information to:

```text
C:\ProgramData\WinTroubleshooter\AuditLog.csv
```

Generated evidence should be reviewed before sharing because Windows logs and reports may contain computer names, usernames, addresses, tenant details or application information.

## Safety notice

This toolkit performs administrative repair and configuration actions. Review the selected action before running it on production systems. Test potentially disruptive operations in a lab or on a non-critical device first. Some functions reset caches, services, networking components, policies, application registrations or system configuration.

External utility functions may download software from Microsoft, GitHub or vendor websites. Confirm the source and comply with your organisation's software policies before use.

## Known limitations

- Results can vary by Windows build, installed software, hardware, security controls and domain or tenant policy.
- Some Microsoft 365 and Entra ID checks require the relevant permissions or administrative modules.
- Vendor-specific printer, VPN and security products may require separate tools.
- A successful repair does not replace backups, change control or vendor-supported recovery procedures.

## Related single-run tools

For technicians who prefer focused tools without menus:

- [Windows Update Repair](https://github.com/IAmLegionVaal/Windows-Update-Repair)
- [Windows System Health Repair](https://github.com/IAmLegionVaal/Windows-System-Health-Repair)
- [Windows Security Audit](https://github.com/IAmLegionVaal/Windows-Security-Audit)
- [Windows Support Bundle](https://github.com/IAmLegionVaal/Windows-Support-Bundle)

## Support scope

The toolkit is intended for trained IT support personnel. It is provided without a warranty and should not replace backups, formal change control or vendor-supported recovery procedures.

> **Testing note:** This was tested by me to be working. User experience may vary.

## Licence

No open-source licence has been assigned yet. All rights are reserved by the author unless a licence is added later.
