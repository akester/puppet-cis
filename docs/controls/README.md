# Controls

One file per CIS chapter. Each row is one control the baseline implements or
deliberately handles differently.

| File | CIS chapter |
|---|---|
| [1-initial-setup.md](1-initial-setup.md) | 1 Initial Setup |
| [2-services.md](2-services.md) | 2 Services |
| [3-network.md](3-network.md) | 3 Network |
| [4-host-based-firewall.md](4-host-based-firewall.md) | 4 Host Based Firewall |
| [5-access-control.md](5-access-control.md) | 5 Access Control |
| [6-logging-and-auditing.md](6-logging-and-auditing.md) | 6 Logging and Auditing |
| [7-system-maintenance.md](7-system-maintenance.md) | 7 System Maintenance |

## Columns

- **ID:** stable control ID, `hl-<area>-<NNN>` (e.g. `hl-sysctl-001`). Never
  reused or renumbered. The same ID names the rspec example and, later, the
  Wazuh SCA check, so a failure anywhere points back to this row.
- **CIS:** recommendation number, or `—` for controls that aren't from CIS
  (e.g. carried over from os_hardening).
- **Setting / Value:** what is enforced and the default value.
- **Status:** Enforced, Monitored, Replaced, N/A, or Omitted (see the key in
  [cis-coverage.md](../cis-coverage.md)).
- **Parameter:** the `baseline::*` parameter that controls it, if any.
- **Notes:** per-host overrides and anything surprising. Longer reasoning goes
  under **Deviations**.

## Tests

Every Enforced control has an rspec example whose description starts with its
ID, in the spec for the class that implements it:

```ruby
it 'hl-sysctl-001: disables IPv4 forwarding' do
  is_expected.to contain_sysctl('net.ipv4.ip_forward').with_value('0')
end
```

Monitored controls have no Puppet test; their Wazuh SCA check covers them.
