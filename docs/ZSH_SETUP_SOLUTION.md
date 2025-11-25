# ZSH Default Shell - Complete Solution

## The Problem

After installing ZSH and running `exec zsh`, it works fine. But when you log out and log back in, you're back to bash!

---

## Why This Happens

### Understanding Shell Sessions

When you SSH into a server, the system reads `/etc/passwd` to determine which shell to start. This file contains your user information, including your default shell.

```bash
# Example /etc/passwd entry:
mykyta:x:1000:1000:,,,:/home/mykyta:/bin/bash
                                      ^^^^^^^^^^
                                      Default shell
```

### What `exec zsh` Actually Does

`exec zsh` replaces your current bash process with a zsh process **only for that session**. It doesn't change your default shell in `/etc/passwd`.

When you disconnect and reconnect, the system reads `/etc/passwd` again and starts your default shell (still bash).

---

## The Complete Solution

### 1. Change Default Shell (Using `chsh`)

The `chsh` (change shell) command updates `/etc/passwd` to set your new default shell.

```bash
# Change default shell to ZSH
chsh -s $(which zsh)

# Verify the change was made:
grep $USER /etc/passwd
# Should show: /usr/bin/zsh at the end
```

### 2. **CRITICAL:** Log Out Completely

**This is the step most people miss!**

The change to `/etc/passwd` doesn't take effect until you start a NEW login session.

```bash
# Exit SSH completely:
exit

# Then SSH back in:
ssh mykyta@home-server

# Now verify:
echo $SHELL
# Should show: /usr/bin/zsh
```

### 3. Verify It Worked

```bash
# Check default shell:
echo $SHELL
# Output: /usr/bin/zsh ✅

# Check currently running shell:
ps -p $$
# Should show: zsh ✅

# Check /etc/passwd entry:
grep $USER /etc/passwd
# Should end with: /usr/bin/zsh ✅
```

---

## Common Mistakes

### ❌ Mistake #1: Not Logging Out Completely

```bash
# This is WRONG:
chsh -s $(which zsh)
exec zsh              # Starts ZSH temporarily
# User thinks it's working...
exit
ssh back in
# Still shows bash! 😢
```

**Why:** `exec zsh` masked the issue. The shell change in `/etc/passwd` wasn't applied because you didn't log out after `chsh`.

### ❌ Mistake #2: Only Using `exec zsh`

```bash
# This is TEMPORARY:
exec zsh              # Starts ZSH for current session only
exit
ssh back in
# Back to bash! 😢
```

**Why:** `exec zsh` is NOT permanent. It's just a temporary workaround.

### ✅ Correct Method

```bash
# Step 1: Change default shell
chsh -s $(which zsh)

# Step 2: Log out completely (REQUIRED)
exit

# Step 3: SSH back in
ssh mykyta@home-server

# Step 4: Verify
echo $SHELL           # Should be /usr/bin/zsh
```

---

## Troubleshooting

### Problem: ZSH works in regular SSH but not in VS Code ⭐ VERY COMMON

**Symptoms:**
- Regular SSH shows ZSH correctly
- VS Code integrated terminal still shows bash
- `/etc/passwd` shows `/usr/bin/zsh` correctly

**Cause:** VS Code Remote SSH has its own terminal settings that override system defaults!

**Solution:**

Create or edit `.vscode/settings.json` in your project:

```json
{
  "terminal.integrated.defaultProfile.linux": "zsh",
  "terminal.integrated.profiles.linux": {
    "zsh": {
      "path": "/usr/bin/zsh",
      "args": []
    }
  },
  "terminal.integrated.inheritEnv": true
}
```

**After creating this file:**
1. Reload VS Code window: `Ctrl+Shift+P` → "Reload Window"
2. Open new terminal: `` Ctrl+` `` (backtick)
3. Verify: `echo $SHELL` should now show `/usr/bin/zsh`

**Alternative:** Set it globally in VS Code User Settings:
1. `Ctrl+Shift+P` → "Preferences: Open Settings (JSON)"
2. Add:
   ```json
   "terminal.integrated.defaultProfile.linux": "zsh"
   ```

---

### Problem: `chsh: PAM: Authentication failure`

**Cause:** You don't have permission to change your shell.

**Solution:** Run with sudo or ask system admin.

```bash
sudo chsh -s $(which zsh) $USER
```

---

### Problem: `/etc/passwd` shows bash after `chsh`

**Cause:** `chsh` command failed silently.

**Solution:** Edit `/etc/passwd` directly (requires sudo):

```bash
# Backup first:
sudo cp /etc/passwd /etc/passwd.backup

# Edit:
sudo nano /etc/passwd

# Find your line:
mykyta:x:1000:1000:,,,:/home/mykyta:/bin/bash

# Change to:
mykyta:x:1000:1000:,,,:/home/mykyta:/usr/bin/zsh

# Save and exit
# Log out and back in
```

---

### Problem: ZSH not in `/etc/shells`

**Cause:** ZSH must be listed in `/etc/shells` for `chsh` to allow it.

**Solution:**

```bash
# Check if ZSH is listed:
cat /etc/shells

# If missing, add it:
command -v zsh | sudo tee -a /etc/shells

# Then try chsh again:
chsh -s $(which zsh)
```

---

### Problem: `$SHELL` shows zsh but prompt looks like bash

**Cause:** Your `.zshrc` might not be loading properly.

**Solution:**

```bash
# Check if .zshrc exists:
ls -la ~/.zshrc

# Check for errors:
source ~/.zshrc

# If errors appear, fix them
# Or reinstall Oh My Zsh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

## How the Installation Script Handles This

The [setup-quality-of-life.sh](./setup-quality-of-life.sh) script includes this at the end:

```bash
# Change default shell to ZSH
echo ""
echo "🐚 Setting ZSH as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to ZSH..."
    chsh -s $(which zsh)
    echo "✅ Default shell changed to ZSH"
    echo ""
    echo "⚠️  IMPORTANT: You need to LOG OUT and LOG BACK IN for this to take effect!"
    echo "   Until then, you can use: exec zsh"
else
    echo "✅ ZSH is already your default shell"
fi
```

This means:
1. ✅ Script runs `chsh` automatically
2. ✅ Script warns you to log out
3. ⚠️ **YOU** must log out and back in

---

## Quick Reference Commands

```bash
# Check what shell you're using:
echo $SHELL              # Shows default shell from /etc/passwd
ps -p $$                 # Shows actual running shell

# Check what's in /etc/passwd:
grep $USER /etc/passwd

# Check available shells:
cat /etc/shells

# Change default shell:
chsh -s $(which zsh)

# Start ZSH temporarily (current session only):
exec zsh

# Verify ZSH is working:
echo $ZSH_VERSION        # Should show version number
```

---

## Linux User Login Process (For Understanding)

When you SSH into the server:

1. **SSH connects** → Server authenticates you
2. **Login shell starts** → System reads `/etc/passwd` for your user
3. **Shell is spawned** → System executes the shell listed in `/etc/passwd`
4. **Config files load** → Shell reads `~/.zshrc` or `~/.bashrc`
5. **Prompt appears** → You see your shell prompt

**Key insight:** Step 3 reads `/etc/passwd` to know which shell to start. If it says bash, you get bash. If it says zsh, you get zsh.

`chsh` modifies `/etc/passwd`, but the change only takes effect for NEW login sessions (step 2-3 above).

---

## Summary

| Command | Effect | Persistent? |
|---------|--------|-------------|
| `exec zsh` | Starts ZSH in current session | ❌ No (session only) |
| `chsh -s $(which zsh)` | Changes default shell in `/etc/passwd` | ✅ Yes (after logout) |
| `chsh` + logout + login | Full permanent change | ✅ Yes |

**Bottom line:** You need BOTH:
1. `chsh -s $(which zsh)` to change the default
2. Complete logout/login to apply the change

---

## References

- `man chsh` - Manual page for change shell command
- `man passwd` - Manual page for passwd file format
- [Oh My Zsh Documentation](https://ohmyz.sh/)
- [ZSH FAQ](https://zsh.sourceforge.io/FAQ/)

---

**Updated:** 2024-11-21
**Related Files:**
- [setup-quality-of-life.sh](./setup-quality-of-life.sh)
- [QOL_TOOLS_GUIDE.md](./QOL_TOOLS_GUIDE.md)
