#!/bin/bash

# Define where the logic script will live
LOGIC_PATH="$HOME/.aliasc_logic.sh"

# 1. Create the logic script with duplicate checking built-in
cat << 'EOF' > "$LOGIC_PATH"
#!/bin/bash
read -p "Enter alias name: " name
read -p "Enter command to run: " cmd

# Check if the alias name already exists in .bash_aliases
if grep -q "alias $name=" ~/.bash_aliases 2>/dev/null; then
    echo "Error: Alias '$name' already exists. Use a different name or edit ~/.bash_aliases manually."
    exit 1
fi

# Append the new alias
echo "alias $name='$cmd'" >> ~/.bash_aliases
echo "Success: Alias '$name' added."
EOF

# 2. Make it executable
chmod +x "$LOGIC_PATH"

# 3. Ensure ~/.bash_aliases exists and is linked in .bashrc
touch ~/.bash_aliases
if ! grep -q ".bash_aliases" ~/.bashrc; then
    echo -e "\nif [ -f ~/.bash_aliases ]; then\n    . ~/.bash_aliases\nfi" >> ~/.bashrc
fi

# 4. Add the 'aliasc' command to .bashrc (if missing)
if ! grep -q "aliasc()" ~/.bashrc; then
    cat << EOF >> ~/.bashrc

aliasc() {
    $LOGIC_PATH
    source ~/.bashrc
}
EOF
    echo "Installed 'aliasc' command."
else
    echo "'aliasc' command is already configured."
fi

# 5. Source it for the current session
# Note: This works if you 'source' the installer, or just restart your shell after.
echo "Setup complete. Please run 'source ~/.bashrc' or restart your terminal."
