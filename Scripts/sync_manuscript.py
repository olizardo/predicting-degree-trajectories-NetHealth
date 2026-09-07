#!/usr/bin/env python3
"""
Scripts/sync_manuscript.py
DOM-based OpenXML table & figure injector adhering strictly to AGENTS.md:
- In-place XML injection preserving live styles, paragraph hierarchies, and page breaks
- 6.5-inch full printable text width scaling (9360 dxa / 5,943,600 EMUs)
- Dual DrawingML extent synchronization (cx, cy)
- Mandatory XML character escaping and strict ECMA-376 tag ordering
- Universal APA 7th table standards (no vertical borders, 1pt top/bottom, 0.5pt header-bottom)
"""

import os
import re
import sys
import zipfile
import struct
import xml.etree.ElementTree as ET

def xml_escape(s):
    if s is None: return ""
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")

def get_png_dimensions(image_path):
    with open(image_path, "rb") as f:
        data = f.read(24)
        if len(data) >= 24 and data.startswith(b'\x89PNG\r\n\x1a\n'):
            return struct.unpack('>II', data[16:24])
    return 1950, 1200

def parse_markdown_table(file_path):
    if not os.path.exists(file_path):
        return [], []
    with open(file_path, "r", encoding="utf-8") as f:
        lines = [line.strip() for line in f if line.strip()]
    table_lines = [line for line in lines if line.startswith("|") and line.endswith("|")]
    if len(table_lines) < 3: return [], []
    headers = [c.strip() for c in table_lines[0].strip("|").split("|")]
    rows = []
    for line in table_lines[2:]:
        row = [c.strip() for c in line.strip("|").split("|")]
        rows.append(row)
    return headers, rows

def format_cell_runs(text, is_header=False):
    parts = re.split(r"<br\s*/?>", text, flags=re.IGNORECASE)
    runs_xml = []
    for idx, part in enumerate(parts):
        if idx > 0:
            runs_xml.append('<w:r><w:br/></w:r>')
        escaped = xml_escape(part.strip())
        if is_header:
            runs_xml.append(f'<w:r><w:rPr><w:b/></w:rPr><w:t>{escaped}</w:t></w:r>')
        else:
            runs_xml.append(f'<w:r><w:t>{escaped}</w:t></w:r>')
    return "".join(runs_xml)

def create_apa_table_xml(headers, rows_data, col_widths=None):
    total_w = 9360  # 6.5 in portrait width in dxa
    num_cols = len(headers)
    if col_widths is None:
        col1_w = int(total_w * 0.38)
        rem_w = total_w - col1_w
        sub_w = int(rem_w / (num_cols - 1))
        col_widths = [col1_w] + [sub_w] * (num_cols - 2)
        col_widths.append(total_w - sum(col_widths))
        
    xml = [f'<w:tbl xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:tblPr><w:tblW w:w="{total_w}" w:type="dxa"/><w:tblBorders><w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/><w:left w:val="none"/><w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/><w:right w:val="none"/><w:insideH w:val="none"/><w:insideV w:val="none"/></w:tblBorders><w:tblCellMar><w:top w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/><w:left w:w="160" w:type="dxa"/><w:right w:w="160" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>']
    for w in col_widths: xml.append(f'<w:gridCol w:w="{w}"/>')
    xml.append('</w:tblGrid>')
    
    # Header Row
    xml.append('<w:tr><w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>')
    for i, h in enumerate(headers):
        align = "left" if i == 0 else "center"
        runs = format_cell_runs(h, is_header=True)
        xml.append(f'<w:tc><w:tcPr><w:tcW w:w="{col_widths[i]}" w:type="dxa"/><w:tcBorders><w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/></w:tcBorders><w:noWrap/></w:tcPr><w:p><w:pPr><w:suppressAutoHyphens/><w:spacing w:before="0" w:after="0"/><w:ind w:left="0" w:right="0" w:firstLine="0" w:hanging="0"/><w:jc w:val="{align}"/></w:pPr>{runs}</w:p></w:tc>')
    xml.append('</w:tr>')
    
    # Data Rows
    for row in rows_data:
        xml.append('<w:tr><w:trPr><w:cantSplit/></w:trPr>')
        for i, val in enumerate(row):
            w_idx = i if i < len(col_widths) else -1
            w_val = col_widths[w_idx]
            align = "left" if i == 0 else "center"
            runs = format_cell_runs(val, is_header=False)
            xml.append(f'<w:tc><w:tcPr><w:tcW w:w="{w_val}" w:type="dxa"/><w:noWrap/></w:tcPr><w:p><w:pPr><w:suppressAutoHyphens/><w:spacing w:before="0" w:after="0"/><w:ind w:left="0" w:right="0" w:firstLine="0" w:hanging="0"/><w:jc w:val="{align}"/></w:pPr>{runs}</w:p></w:tc>')
        xml.append('</w:tr>')
    xml.append('</w:tbl>')
    return "".join(xml)

def generate_table_xmls():
    tables = {}
    h1, r1 = parse_markdown_table("cache/table1_decomposed_trajectory_means.md")
    if h1: tables["Table 1"] = create_apa_table_xml(h1, r1, [2360, 1200, 1450, 1450, 1450, 1450])
    
    h2, r2 = parse_markdown_table("cache/table2_lcga_model_selection.md")
    if h2: tables["Table 2"] = create_apa_table_xml(h2, r2, [2000, 1500, 1200, 1500, 1500, 1660])
    
    h3, r3 = parse_markdown_table("cache/table3_mlogit_lcga_predictors.md")
    if h3: tables["Table 3"] = create_apa_table_xml(h3, r3, [2560, 1100, 1200, 900, 1100, 1200, 900])
    
    hA1, rA1 = parse_markdown_table("cache/tableA1_multilevel_glmm_estimates.md")
    if hA1: tables["Table A1"] = create_apa_table_xml(hA1, rA1, [3600, 1800, 2360, 1600])
    
    return tables

def create_drawing_xml(rId, img_path):
    pw, ph = get_png_dimensions(img_path)
    cx = 5943600  # 6.5 in portrait width in EMUs
    cy = int(round(5943600 * (ph / pw)))
    
    return (
        f'<w:p xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        f'<w:pPr><w:ind w:left="0" w:right="0" w:firstLine="0" w:hanging="0"/><w:jc w:val="center"/><w:spacing w:before="120" w:after="120"/></w:pPr>'
        f'<w:r><w:drawing xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        f'<wp:inline distT="0" distB="0" distL="0" distR="0">'
        f'<wp:extent cx="{cx}" cy="{cy}"/>'
        f'<wp:effectExtent l="0" t="0" r="0" b="0"/>'
        f'<wp:docPr id="101" name="Figure"/>'
        f'<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>'
        f'<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        f'<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        f'<pic:nvPicPr><pic:cNvPr id="101" name="Picture"/><pic:cNvPicPr/></pic:nvPicPr>'
        f'<pic:blipFill>'
        f'<a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="{rId}"/>'
        f'<a:stretch><a:fillRect/></a:stretch>'
        f'</pic:blipFill>'
        f'<pic:spPr>'
        f'<a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm>'
        f'<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
        f'</pic:spPr>'
        f'</pic:pic>'
        f'</a:graphicData></a:graphic>'
        f'</wp:inline></w:drawing></w:r></w:p>'
    )

def sync_docx(in_docx, out_docx, inject_tables=True):
    with zipfile.ZipFile(in_docx, "r") as zin:
        xml_bytes = zin.read("word/document.xml")
        rels_bytes = zin.read("word/_rels/document.xml.rels")
        all_files = {item.filename: zin.read(item.filename) for item in zin.infolist()}
    
    ET.register_namespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    ET.register_namespace('a', 'http://schemas.openxmlformats.org/drawingml/2006/main')
    ET.register_namespace('r', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
    ET.register_namespace('wp', 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing')
    ET.register_namespace('pic', 'http://schemas.openxmlformats.org/drawingml/2006/picture')
    
    doc_tree = ET.fromstring(xml_bytes)
    root_rels = ET.fromstring(rels_bytes)
    
    ns = {
        'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
        'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
        'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
        'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
        'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture'
    }
    body = doc_tree.find('w:body', ns)
    
    # 1. Figure Tag Replacement
    figure_tags = {
        "{{FIGURE_1}}": "Plots/fig1_decomposed_degree_trajectories.png",
        "{{FIGURE_2}}": "Plots/fig2_lcga_8wave_trajectories.png",
        "{{FIGURE_3}}": "Plots/fig3_lcga_functional_profiles.png",
        "{{FIGURE_4}}": "Plots/fig4_mlogit_forest_plot.png",
        "{{FIGURE_A1}}": "Plots/figA1_multilevel_predicted_trajectories.png"
    }
    
    existing_rids = [e.get('Id') for e in root_rels if e.get('Id', '').startswith('rId')]
    max_rid_num = max([int(r[3:]) for r in existing_rids if r[3:].isdigit()] + [0])
    existing_images = [f for f in all_files.keys() if f.startswith('word/media/image')]
    max_img_num = max([int(re.search(r'image(\d+)', f).group(1)) for f in existing_images if re.search(r'image(\d+)', f)] + [0])

    for elem in list(body):
        text = ''.join(elem.itertext()).strip()
        for tag, img_path in figure_tags.items():
            if tag in text and os.path.exists(img_path):
                max_rid_num += 1
                max_img_num += 1
                new_rid = f"rId{max_rid_num}"
                img_name = f"image{max_img_num}.png"
                target_media = f"word/media/{img_name}"

                with open(img_path, "rb") as f_img:
                    all_files[target_media] = f_img.read()

                rel_elem = ET.Element('{http://schemas.openxmlformats.org/package/2006/relationships}Relationship')
                rel_elem.set('Id', new_rid)
                rel_elem.set('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image')
                rel_elem.set('Target', f'media/{img_name}')
                root_rels.append(rel_elem)

                draw_p = ET.fromstring(create_drawing_xml(new_rid, img_path))
                idx = list(body).index(elem)
                body.remove(elem)
                body.insert(idx, draw_p)
                print(f"  [Tag Injection] Replaced {tag} with drawing {new_rid} -> {target_media}")
                break

    # 2. Table Tag Replacement
    if inject_tables:
        tables = generate_table_xmls()
        table_tags = {
            "{{TABLE_1}}": "Table 1",
            "{{TABLE_2}}": "Table 2",
            "{{TABLE_3}}": "Table 3",
            "{{TABLE_4}}": "Table 4",
            "{{TABLE_5}}": "Table 5",
            "{{TABLE_6}}": "Table 6"
        }

        for elem in list(body):
            text = ''.join(elem.itertext()).strip()
            for tag, tab_key in table_tags.items():
                if tag in text and tab_key in tables:
                    tbl_elem = ET.fromstring(tables[tab_key])
                    idx = list(body).index(elem)
                    body.remove(elem)
                    body.insert(idx, tbl_elem)
                    print(f"  [Table Tag Injection] Replaced {tag} with {tab_key}")
                    break

    # Serialize back cleanly
    all_files["word/document.xml"] = ET.tostring(doc_tree, encoding="utf-8", xml_declaration=True)
    all_files["word/_rels/document.xml.rels"] = ET.tostring(root_rels, encoding="utf-8", xml_declaration=True)

    with zipfile.ZipFile(out_docx, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for fname, data in all_files.items():
            zout.writestr(fname, data)

    print(f"Successfully synced OpenXML: {in_docx} -> {out_docx}")

if __name__ == "__main__":
    if len(sys.argv) >= 3:
        sync_docx(sys.argv[1], sys.argv[2], inject_tables=True)
    else:
        print("Usage: python3 sync_manuscript.py input.docx output.docx")
