const SUPABASE_URL = 'https://pgocytcgxcbzqvntnitb.supabase.co';
const SUPABASE_KEY = 'sb_publishable_0FLoOrtR5FlVkAIKmtoo8g_3DUUXDH3';
const SITE = 'https://shwepinyanandaw.org';

function esc(s) {
  return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
  });
}

module.exports = async function (req, res) {
  var id = String(req.query.id || '');
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(id)) {
    res.statusCode = 302; res.setHeader('Location', SITE + '/blog.html'); return res.end();
  }
  var post = null;
  try {
    var r = await fetch(SUPABASE_URL + '/rest/v1/posts?id=eq.' + encodeURIComponent(id) +
      '&published=eq.true&select=id,title,body,image_path&limit=1',
      { headers: { apikey: SUPABASE_KEY } });
    var rows = await r.json();
    post = Array.isArray(rows) && rows[0];
  } catch (e) {}
  if (!post) {
    res.statusCode = 302; res.setHeader('Location', SITE + '/blog.html'); return res.end();
  }
  var title = esc(post.title);
  var desc = esc((post.body || '').replace(/\s+/g, ' ').slice(0, 200));
  var image = esc(post.image_path || SITE + '/photos/school-logo.png');
  var target = SITE + '/blog.html?id=' + id;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');
  res.end('<!doctype html><html><head><meta charset="utf-8">' +
    '<title>' + title + '</title>' +
    '<meta property="og:type" content="article">' +
    '<meta property="og:site_name" content="Shwe Pinya Nandaw Private High School">' +
    '<meta property="og:title" content="' + title + '">' +
    '<meta property="og:description" content="' + desc + '">' +
    '<meta property="og:image" content="' + image + '">' +
    '<meta property="og:url" content="' + SITE + '/share/' + esc(id) + '">' +
    '<meta name="twitter:card" content="summary_large_image">' +
    '<meta http-equiv="refresh" content="0;url=' + target + '">' +
    '</head><body><script>location.replace(' + JSON.stringify(target) + ');</script>' +
    '<a href="' + target + '">Read the post</a></body></html>');
};
