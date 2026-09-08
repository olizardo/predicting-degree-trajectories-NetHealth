import os
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

def xml_escape(s):
    if s is None: return ""
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")

def sync_text(in_docx, out_docx):
    with zipfile.ZipFile(in_docx, "r") as zin:
        xml_bytes = zin.read("word/document.xml")
        all_files = {item.filename: zin.read(item.filename) for item in zin.infolist()}
    
    ET.register_namespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    doc_tree = ET.fromstring(xml_bytes)
    ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
    body = doc_tree.find('w:body', ns)
    
    target_text = "Rather than maintaining diffuse, passive networks, extraverts aggressively channel their social bandwidth into either building massive supportive cores or rapidly shedding low-investment peripheral ties as time demands escalate."
    replacement = "Rather than maintaining diffuse, passive networks, extraverts aggressively channel their social bandwidth into either building massive supportive cores or rapidly shedding low-investment peripheral ties as time demands escalate. To clarify, the sorting of extraverted students into “winnowing” trajectories reflects their longitudinal slope rather than a low starting intercept: while extraverts arrive at college with significantly larger baseline networks than introverts, they shed those peripheral ties at a much faster rate over time, which mathematically defines the winnowing classes."
    
    for p in body.findall('w:p', ns):
        text = ''.join(p.itertext()).strip()
        if target_text in text:
            # We found the paragraph. Let's just rewrite its runs while preserving <w:pPr>.
            pPr = p.find('w:pPr', ns)
            # Remove all children
            for child in list(p):
                p.remove(child)
            # Re-add pPr if it existed
            if pPr is not None:
                p.append(pPr)
            # Replace text in the paragraph
            new_text = text.replace(target_text, replacement)
            
            # Simple run creation for the new text
            r = ET.Element('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}r')
            t = ET.Element('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t')
            t.text = new_text
            r.append(t)
            p.append(r)
            print("Successfully updated paragraph in document.xml.")
            break

    all_files["word/document.xml"] = ET.tostring(doc_tree, encoding="utf-8", xml_declaration=True)

    with zipfile.ZipFile(out_docx, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for fname, data in all_files.items():
            zout.writestr(fname, data)

if __name__ == "__main__":
    if len(sys.argv) >= 3:
        sync_text(sys.argv[1], sys.argv[2])
