
# TLDR; Oneline fresh installation (including repo cloning)
git clone https://github.com/Motyak/ml-tools.git ~/.local/share/ml-tools && cd $_ && ./install.sh

---

# Update & Build & Install
./install.sh

# Update & Build (but don't install)
./build.sh

# Uninstall (remove symlinks)
./uninstall.sh

---

# Once installed, you can update by running ./update_repo.sh,
# followed by ./build.sh
