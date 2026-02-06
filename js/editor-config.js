/**
 * Single source for editor config shared by NW and web app.
 * @version 1.2.0
 */
window.EDITOR_XSLT_CONFIG = {
  importSvgXsltHref: [
    '../xslt/page2svg.xslt',
    '../xslt/page_from_2010-03-19.xslt',
    '../xslt/page2page.xslt',
    '../xslt/alto_v2_to_page.xslt',
    '../xslt/alto_v3_to_page.xslt'
  ],
  exportSvgXsltHref: [
    '../xslt/svg2page.xslt',
    '../xslt/sortattr.xslt',
    '../xslt/page_fix_xsd_sequence.xslt'
  ]
};
