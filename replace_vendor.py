import os

replacements = {
    "Vendor(": "User(",
    "[Vendor]": "[User]",
    "var vendor: Vendor": "var vendor: User",
    "let vendor: Vendor": "let vendor: User",
    "var allVendors: [Vendor]": "var allVendors: [User]",
    "func addVendor(_ vendor: Vendor": "func addVendor(_ vendor: User",
    "func addVendor(vendor: Vendor": "func addVendor(vendor: User",
    "func getAllVendors(completion: @escaping ([Vendor]?": "func getAllVendors(completion: @escaping ([User]?",
    "var vendors: [Vendor] = []": "var vendors: [User] = []",
}

for root, _, files in os.walk("ALP_SE_EVO"):
    for file in files:
        if file.endswith(".swift") and file != "Vendor.swift":
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            
            original = content
            for k, v in replacements.items():
                content = content.replace(k, v)
                
            if content != original:
                with open(path, "w") as f:
                    f.write(content)
                print(f"Updated {path}")
