# Alerts and what to do about them

Every alert in this lab has a defined response. An alert nobody knows how to act on
is noise, and noise is how real alerts get ignored.

## VM unavailable — Severity 1

**Means:** the Azure platform cannot reach the VM. Users see nothing at all.

1. Azure Portal → the VM → **Overview**: is the status *Running* or *Stopped*?
2. If stopped, check **Activity log** — was it deallocated, did it crash, or did a
   deployment restart it?
3. Start it, then confirm Nginx came back: `systemctl status nginx`.
4. If it is running but still unreachable, check the NSG rules — an edit to the
   security rules is the usual cause.
5. Record the start time, the cause and the fix.

## CPU above 80% for 10 minutes — Severity 2

**Means:** something is consuming the server. On a B1s this is often the burst
credits running out rather than a runaway process.

1. SSH in and run `top -b -n1 | head -20`.
2. If a process is genuinely stuck, restart that service, not the whole VM.
3. If Nginx is simply serving more traffic than a B1s can handle, the answer is a
   bigger `vm_size` in Terraform, not a one-off portal change.
4. Check **Monitoring → Metrics → CPU Credits Remaining** before blaming a process.

## Disk free below 15% — Warning

Collected by the Azure Monitor Agent as a guest metric; the VM metric alerts above
do not see inside the disk.

1. `df -h` to confirm, then `du -sh /var/log/* | sort -h | tail`.
2. Usual culprits: `/var/log` and old backup archives in `/var/backups/weblab`.
3. The backup script rotates to 7 copies, so if backups are filling the disk, check
   whether the rotation step is failing in `/var/log/weblab-backup.log`.
4. Never delete application data to free space. Escalate instead.

## Monthly: test the restore

A backup that has never been restored is an assumption, not a backup.

```bash
# newest backup from the container
azcopy copy "https://<account>.blob.core.windows.net/backups/?<SAS>" ./restore --recursive

# restore it somewhere harmless and compare
mkdir -p /tmp/restore-test
tar -xzf ./restore/webroot-<stamp>.tar.gz -C /tmp/restore-test
diff -r /tmp/restore-test/html /var/www/html && echo "restore verified"
```

Write down the date of each successful restore test. That date is the real measure
of whether the backup works.
