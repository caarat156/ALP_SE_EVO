import os
import sys

def run_conversion():
    md_path = "/Users/student/.gemini/antigravity-ide/brain/28ef8cfb-b2ea-4656-9a56-d2d701473852/test_plan.md"
    html_path = "/Users/student/Documents/ALP_SE_EVO/Test_Plan_Tengkiawan_Family.html"
    docx_path = "/Users/student/Documents/ALP_SE_EVO/Test_Plan_Tengkiawan_Family.docx"
    
    if not os.path.exists(md_path):
        print(f"Error: Markdown file not found at {md_path}")
        sys.exit(1)
        
    with open(md_path, 'r', encoding='utf-8') as f:
        md_content = f.read()
        
    lines = md_content.split('\n')
    html_lines = []
    
    in_table = False
    in_list = False
    is_cover = True
    
    html_lines.append("<html><head><meta charset='utf-8'>")
    html_lines.append("<style>")
    html_lines.append("body { font-family: 'Arial', sans-serif; line-height: 1.4; color: #000000; margin: 30px; }")
    html_lines.append("h1 { text-align: center; font-size: 24pt; margin-top: 100px; color: #111111; }")
    html_lines.append("h2 { border-bottom: 1.5pt solid #444444; padding-bottom: 3px; margin-top: 30px; font-size: 16pt; color: #222222; }")
    html_lines.append("h3 { margin-top: 20px; font-size: 13pt; color: #333333; }")
    html_lines.append("p { margin: 8px 0; font-size: 10.5pt; }")
    html_lines.append("ul { margin: 8px 0 8px 20px; font-size: 10.5pt; }")
    html_lines.append("li { margin: 4px 0; }")
    html_lines.append("hr { border: 0; border-top: 1px solid #cccccc; margin: 25px 0; }")
    html_lines.append(".cover { text-align: center; margin-top: 80px; page-break-after: always; }")
    html_lines.append("</style></head><body>")
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        # Divider / Cover breaker
        if line.startswith("***"):
            if is_cover:
                html_lines.append("</div>") # close cover div
                html_lines.append("<div style='page-break-before: always;'>")
                is_cover = False
            else:
                html_lines.append("<hr/>")
            i += 1
            continue
            
        if is_cover and i == 0:
            html_lines.append("<div class='cover'>")
            
        # Headers
        if line.startswith("# "):
            title = line[2:]
            html_lines.append(f"<h1>{title}</h1>")
        elif line.startswith("## "):
            title = line[3:]
            html_lines.append(f"<h2>{title}</h2>")
        elif line.startswith("### "):
            title = line[4:].replace("**", "")
            html_lines.append(f"<h3>{title}</h3>")
        elif line.startswith("#### "):
            title = line[5:].replace("**", "")
            html_lines.append(f"<h4>{title}</h4>")
            
        # Tables
        elif line.startswith("|"):
            if not in_table:
                in_table = True
                # Use legacy attributes for tables (border=1, cellpadding=6, cellspacing=0)
                html_lines.append('<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse; width:100%; border:1px solid #000000; margin:15px 0;">')
            
            parts = [p.strip() for p in line.split('|')[1:-1]]
            if all(p.startswith('-') or p.endswith('-') for p in parts if p):
                i += 1
                continue
                
            tag = "th" if html_lines[-1].startswith("<table") else "td"
            row_html = "<tr>"
            for p in parts:
                p_cleaned = p.replace("**", "<b>").replace("</b>", "")
                p_cleaned = p_cleaned.replace("<br>", "<br/>")
                p_cleaned = p_cleaned.replace(r"\le", "&le;")
                p_cleaned = p_cleaned.replace(r"\rightarrow", "&rarr;")
                
                # strip markdown link syntax [label](url) -> label
                while "[" in p_cleaned and "]" in p_cleaned:
                    start_lbl = p_cleaned.find("[")
                    end_lbl = p_cleaned.find("]")
                    lbl = p_cleaned[start_lbl+1:end_lbl]
                    url_start = p_cleaned.find("(", end_lbl)
                    url_end = p_cleaned.find(")", url_start)
                    if url_start != -1 and url_end != -1:
                        p_cleaned = p_cleaned[:start_lbl] + lbl + p_cleaned[url_end+1:]
                    else:
                        break
                
                bg_color = ' bgcolor="#f2f2f2"' if tag == "th" else ""
                row_html += f'<{tag}{bg_color} style="border:1px solid #000000; padding:6px; font-size:10pt;">{p_cleaned}</{tag}>'
            row_html += "</tr>"
            html_lines.append(row_html)
            
        # Lists
        elif line.startswith("*") or line.startswith("-"):
            if in_table:
                in_table = False
                html_lines.append("</table>")
            if not in_list:
                in_list = True
                html_lines.append("<ul>")
            content = line[1:].strip().replace("**", "<b>").replace("</b>", "")
            content = content.replace(r"\le", "&le;")
            content = content.replace(r"\rightarrow", "&rarr;")
            while "[" in content and "]" in content:
                start_lbl = content.find("[")
                end_lbl = content.find("]")
                lbl = content[start_lbl+1:end_lbl]
                url_start = content.find("(", end_lbl)
                url_end = content.find(")", url_start)
                if url_start != -1 and url_end != -1:
                    content = content[:start_lbl] + lbl + content[url_end+1:]
                else:
                    break
            html_lines.append(f"<li>{content}</li>")
            
        # Paragraphs or empty lines
        else:
            if in_table:
                in_table = False
                html_lines.append("</table>")
            if in_list:
                in_list = False
                html_lines.append("</ul>")
                
            if line:
                line_formatted = line.replace("**", "<b>").replace("</b>", "")
                line_formatted = line_formatted.replace(r"\le", "&le;")
                line_formatted = line_formatted.replace(r"\rightarrow", "&rarr;")
                while "[" in line_formatted and "]" in line_formatted:
                    start_lbl = line_formatted.find("[")
                    end_lbl = line_formatted.find("]")
                    lbl = line_formatted[start_lbl+1:end_lbl]
                    url_start = line_formatted.find("(", end_lbl)
                    url_end = line_formatted.find(")", url_start)
                    if url_start != -1 and url_end != -1:
                        line_formatted = line_formatted[:start_lbl] + lbl + line_formatted[url_end+1:]
                    else:
                        break
                html_lines.append(f"<p>{line_formatted}</p>")
                
        i += 1
        
    if in_table:
        html_lines.append("</table>")
    if in_list:
        html_lines.append("</ul>")
    if not is_cover:
        html_lines.append("</div>")
        
    html_lines.append("</body></html>")
    
    html_content = '\n'.join(html_lines)
    
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    print(f"Generated intermediate HTML file")
    
    # Run textutil
    os.system(f"textutil -convert docx {html_path} -output {docx_path}")
    print(f"Generated Word document")
    
    if os.path.exists(html_path):
        os.remove(html_path)

if __name__ == "__main__":
    run_conversion()
