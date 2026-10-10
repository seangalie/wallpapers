/*
  Gallery for Sean's Wallpaper Archive. Renders the collection that
  scripts/build-site.sh embeds in index.html, filters it, and shows each
  wallpaper in a viewer with a download button. This replaces the template's
  jQuery, Poptrox, and main.js, which expect a fixed list of images, while
  keeping the template's markup and styles.
*/
(function () {
  'use strict';

  // Display formats in the order the README lists them.
  const FORMATS = [
    { id: 'desktops', label: 'Desktops' },
    { id: 'ultrawide', label: 'Ultrawide' },
    { id: 'dual', label: 'Dual' },
    { id: 'triple', label: 'Triple' },
    { id: 'mobile', label: 'Mobile' },
    { id: 'square', label: 'Square' },
  ];
  const CATEGORY_LABELS = { scifi: 'Sci-Fi' };
  // The long side of the lightbox previews, from PREVIEW_SETTINGS.
  const PREVIEW_SIZE = 1920;
  // The template's space around the viewer on larger screens.
  const VIEWER_MARGIN = 50;

  const body = document.body;
  const main = document.getElementById('main');
  const collection = JSON.parse(document.getElementById('collection').textContent);
  const numbers = new Intl.NumberFormat('en-US');
  const smallScreen = window.matchMedia('(max-width: 736px)');

  const titleCase = (words) =>
    words.split('-').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
  const formatLabel = (id) => FORMATS.find((format) => format.id === id).label;
  const categoryLabel = (id) => CATEGORY_LABELS[id] || titleCase(id);
  const megabytes = (bytes) => `${(bytes / 1e6).toFixed(1)} MB`;
  const mediaUrl = (image) =>
    `https://media.githubusercontent.com/media/${collection.repository}/${collection.ref}/${image.path}`;

  // A theme prefix such as nord_ becomes "Nord: ".
  function imageTitle(name) {
    const parts = name.replace(/\.[^.]+$/, '').split('_');
    return parts.map(titleCase).join(': ');
  }

  const formatOrder = FORMATS.map((format) => format.id);
  const images = collection.images
    .map((image) => {
      const [, format, category, name] = image.path.split('/');
      return {
        ...image,
        format,
        category,
        name,
        title: imageTitle(name),
        terms: `${format} ${category} ${name}`.replace(/[-_.]/g, ' '),
      };
    })
    .sort((a, b) =>
      formatOrder.indexOf(a.format) - formatOrder.indexOf(b.format)
      || a.category.localeCompare(b.category)
      || a.name.localeCompare(b.name));
  const categories = [...new Set(images.map((image) => image.category))]
    .sort((a, b) => categoryLabel(a).localeCompare(categoryLabel(b)));

  document.querySelectorAll('[data-repository-link]').forEach((link) => {
    link.href = `https://github.com/${collection.repository}${link.dataset.repositoryLink}`;
  });

  // --- Grid -----------------------------------------------------------------

  // Thumbnails load as their tiles near the screen, so opening the page does
  // not fetch the whole collection's previews.
  const thumbnails = 'IntersectionObserver' in window
    ? new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          loadThumbnail(entry.target);
          thumbnails.unobserve(entry.target);
        }
      });
    }, { rootMargin: '600px 0px' })
    : null;

  function loadThumbnail(article) {
    const image = images[article.dataset.index];
    article.firstChild.style.backgroundImage = `url("previews/${image.oid}-thumb.webp")`;
  }

  const fragment = document.createDocumentFragment();
  images.forEach((image, index) => {
    const article = document.createElement('article');
    article.className = 'thumb';
    article.dataset.index = index;

    const link = document.createElement('a');
    link.className = 'image';
    link.href = `previews/${image.oid}.webp`;
    link.setAttribute('aria-label',
      `${image.title}, ${formatLabel(image.format)}, ${categoryLabel(image.category)}`);
    link.addEventListener('click', (event) => {
      event.preventDefault();
      openViewer(image);
    });

    const heading = document.createElement('h2');
    heading.textContent = image.title;

    article.append(link, heading);
    image.article = article;
    fragment.append(article);
    if (thumbnails) thumbnails.observe(article); else loadThumbnail(article);
  });
  main.append(fragment);

  // --- Filters --------------------------------------------------------------

  const state = { format: '', category: '', query: '' };
  let visible = images;

  const search = document.getElementById('search');
  const summary = document.getElementById('summary');
  const showResults = document.getElementById('show-results');
  const empty = document.getElementById('empty');

  function matches(image, ignore) {
    if (ignore !== 'format' && state.format && image.format !== state.format) return false;
    if (ignore !== 'category' && state.category && image.category !== state.category) return false;
    const words = state.query.toLowerCase().split(/\s+/).filter(Boolean);
    return words.every((word) => image.terms.includes(word));
  }

  function filterButtons(list, key, options) {
    return [{ id: '', label: options.all }, ...options.items].map((item) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.append(item.label);
      const count = document.createElement('span');
      count.className = 'count';
      button.append(count);
      button.addEventListener('click', () => {
        state[key] = item.id;
        update({ scroll: true });
      });
      const entry = document.createElement('li');
      entry.append(button);
      list.append(entry);
      return { id: item.id, button, count };
    });
  }

  const formatButtons = filterButtons(document.getElementById('format-filters'), 'format', {
    all: 'All formats',
    items: FORMATS.filter((format) => images.some((image) => image.format === format.id)),
  });
  const categoryButtons = filterButtons(document.getElementById('category-filters'), 'category', {
    all: 'All categories',
    items: categories.map((id) => ({ id, label: categoryLabel(id) })),
  });

  function refreshButtons(buttons, key) {
    const pool = images.filter((image) => matches(image, key));
    buttons.forEach(({ id, button, count }) => {
      const total = id ? pool.filter((image) => image[key] === id).length : pool.length;
      count.textContent = numbers.format(total);
      button.setAttribute('aria-pressed', String(state[key] === id));
      button.disabled = total === 0 && state[key] !== id;
    });
  }

  function update({ scroll = false } = {}) {
    visible = images.filter((image) => matches(image));
    const shown = new Set(visible);
    images.forEach((image) => { image.article.hidden = !shown.has(image); });
    empty.hidden = visible.length > 0;

    refreshButtons(formatButtons, 'format');
    refreshButtons(categoryButtons, 'category');

    const noun = visible.length === 1 ? 'wallpaper' : 'wallpapers';
    const parts = [`${numbers.format(visible.length)} ${noun}`];
    if (state.format) parts.push(formatLabel(state.format));
    if (state.category) parts.push(categoryLabel(state.category));
    if (state.query.trim()) parts.push(`“${state.query.trim()}”`);
    summary.textContent = parts.join(' · ');
    showResults.textContent = `Show ${numbers.format(visible.length)} ${noun}`;

    writeHash();
    if (scroll) window.scrollTo(0, 0);
  }

  let searchTimer;
  search.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      state.query = search.value;
      update({ scroll: true });
    }, 150);
  });

  document.querySelectorAll('[data-reset]').forEach((link) => {
    link.addEventListener('click', (event) => {
      event.preventDefault();
      state.format = '';
      state.category = '';
      state.query = '';
      search.value = '';
      update({ scroll: true });
    });
  });

  // --- Address --------------------------------------------------------------

  // Filters and the open wallpaper live in the URL's hash, such as
  // #format=dual&category=space&view=wallpapers/dual/space/name.jpg, so a
  // view can be bookmarked or shared.
  function writeHash() {
    const params = new URLSearchParams();
    if (state.format) params.set('format', state.format);
    if (state.category) params.set('category', state.category);
    if (state.query.trim()) params.set('q', state.query.trim());
    if (viewer.image) params.set('view', viewer.image.path);
    const hash = params.toString();
    history.replaceState(null, '', hash ? `#${hash}` : location.pathname + location.search);
  }

  function readHash() {
    const params = new URLSearchParams(location.hash.slice(1));
    const format = params.get('format') || '';
    const category = params.get('category') || '';
    state.format = formatOrder.includes(format) ? format : '';
    state.category = categories.includes(category) ? category : '';
    state.query = params.get('q') || '';
    search.value = state.query;
    return images.find((image) => image.path === params.get('view'));
  }

  // --- Panels ---------------------------------------------------------------

  // The template's sliding panels: a toggle is any link to the panel's id.
  const panels = [...document.querySelectorAll('.panel')];

  function hidePanels() {
    panels.forEach((panel) => panel.classList.remove('active'));
    document.querySelectorAll('#header nav a').forEach((link) => link.classList.remove('active'));
    body.classList.remove('content-active');
  }

  function showPanel(panel) {
    hidePanels();
    panel.classList.add('active');
    document.querySelectorAll(`#header nav a[href="#${panel.id}"]`)
      .forEach((link) => link.classList.add('active'));
    body.classList.add('content-active');
    if (panel.id === 'browse' && !smallScreen.matches) search.focus({ preventScroll: true });
  }

  panels.forEach((panel) => {
    const closer = document.createElement('div');
    closer.className = 'closer';
    closer.addEventListener('click', hidePanels);
    panel.append(closer);
    panel.addEventListener('click', (event) => event.stopPropagation());

    document.querySelectorAll(`[href="#${panel.id}"]`).forEach((toggle) => {
      toggle.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        if (panel.classList.contains('active')) hidePanels(); else showPanel(panel);
      });
    });
  });

  body.addEventListener('click', (event) => {
    if (body.classList.contains('content-active')) {
      event.preventDefault();
      event.stopPropagation();
      hidePanels();
    }
  });

  // --- Viewer ---------------------------------------------------------------

  const viewer = {
    root: document.getElementById('viewer'),
    popup: document.querySelector('#viewer .poptrox-popup'),
    picture: document.querySelector('#viewer .pic img'),
    title: document.getElementById('viewer-title'),
    details: document.getElementById('viewer-details'),
    download: document.getElementById('viewer-download'),
    original: document.getElementById('viewer-original'),
    list: [],
    image: null,
    returnFocus: null,
  };

  // The viewer shows the preview at its own size or smaller, fitted to the
  // window. Small screens put the details under the image.
  function fitViewer() {
    const { width, height } = viewer.image;
    const scale = Math.min(1, PREVIEW_SIZE / Math.max(width, height));
    const margin = smallScreen.matches ? 0 : VIEWER_MARGIN;
    const room = {
      width: window.innerWidth - 2 * margin,
      height: smallScreen.matches ? window.innerHeight * 0.7 : window.innerHeight - 2 * margin,
    };
    const fit = Math.min(1, room.width / (width * scale), room.height / (height * scale));
    viewer.picture.style.width = `${Math.round(width * scale * fit)}px`;
    viewer.picture.style.height = `${Math.round(height * scale * fit)}px`;
  }

  function showImage(image) {
    viewer.image = image;
    viewer.popup.classList.add('loading');
    viewer.popup.classList.toggle('single', viewer.list.length < 2);
    fitViewer();

    const source = `previews/${image.oid}.webp`;
    viewer.picture.onload = () => {
      if (viewer.picture.getAttribute('src') === source) viewer.popup.classList.remove('loading');
    };
    viewer.picture.src = source;
    viewer.picture.alt = image.title;

    viewer.title.textContent = image.title;
    viewer.details.textContent = [
      formatLabel(image.format),
      categoryLabel(image.category),
      `${numbers.format(image.width)} × ${numbers.format(image.height)}`,
      megabytes(image.bytes),
    ].join(' · ');
    viewer.download.href = mediaUrl(image);
    viewer.download.download = image.name;
    viewer.original.href = mediaUrl(image);

    // Fetch the neighbors' previews so stepping through feels instant.
    [-1, 1].forEach((step) => { new Image().src = `previews/${neighbor(step).oid}.webp`; });
    writeHash();
  }

  function neighbor(step) {
    const index = viewer.list.indexOf(viewer.image);
    return viewer.list[(index + step + viewer.list.length) % viewer.list.length];
  }

  function openViewer(image) {
    viewer.list = visible.includes(image) ? visible : [image];
    viewer.returnFocus = document.activeElement;
    viewer.root.hidden = false;
    body.classList.add('modal-active');
    showImage(image);
    viewer.root.querySelector('.closer').focus({ preventScroll: true });
  }

  function closeViewer() {
    if (!viewer.image) return;
    viewer.root.hidden = true;
    body.classList.remove('modal-active');
    viewer.image = null;
    viewer.picture.removeAttribute('src');
    writeHash();
    // A viewer opened from the address has nothing to return focus to.
    if (viewer.returnFocus && viewer.returnFocus !== body) {
      viewer.returnFocus.focus({ preventScroll: true });
    } else {
      document.activeElement.blur();
    }
  }

  viewer.root.querySelector('.closer').addEventListener('click', closeViewer);
  viewer.root.querySelector('.nav-previous').addEventListener('click', () => showImage(neighbor(-1)));
  viewer.root.querySelector('.nav-next').addEventListener('click', () => showImage(neighbor(1)));
  viewer.root.addEventListener('click', (event) => {
    if (event.target === viewer.root) closeViewer();
  });
  window.addEventListener('resize', () => { if (viewer.image) fitViewer(); });

  // Swipe between wallpapers on touch screens, where the arrows are hidden.
  let touchStart = null;
  viewer.picture.addEventListener('touchstart', (event) => {
    touchStart = event.touches.length === 1 ? event.touches[0] : null;
  }, { passive: true });
  viewer.picture.addEventListener('touchend', (event) => {
    if (!touchStart || viewer.list.length < 2) return;
    const dx = event.changedTouches[0].clientX - touchStart.clientX;
    const dy = event.changedTouches[0].clientY - touchStart.clientY;
    if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy)) showImage(neighbor(dx < 0 ? 1 : -1));
    touchStart = null;
  });

  // Fetching the image and saving it as a file gives it its own name, where a
  // plain link would open it in the browser: the download attribute does not
  // apply across origins. media.githubusercontent.com allows the request.
  viewer.download.addEventListener('click', async (event) => {
    event.preventDefault();
    const button = viewer.download;
    if (button.classList.contains('is-busy')) return;
    const image = viewer.image;
    button.classList.add('is-busy');
    button.textContent = 'Downloading…';
    try {
      const response = await fetch(mediaUrl(image));
      if (!response.ok) throw new Error(`HTTP ${response.status} for ${image.path}`);
      const file = URL.createObjectURL(await response.blob());
      const link = document.createElement('a');
      link.href = file;
      link.download = image.name;
      body.append(link);
      link.click();
      link.remove();
      setTimeout(() => URL.revokeObjectURL(file), 60000);
      button.textContent = 'Download';
    } catch (error) {
      console.error('Download failed:', error);
      button.textContent = 'Failed: try Open full size';
      setTimeout(() => { button.textContent = 'Download'; }, 4000);
    } finally {
      button.classList.remove('is-busy');
    }
  });

  // --- Keyboard -------------------------------------------------------------

  document.addEventListener('keydown', (event) => {
    if (viewer.image) {
      if (event.key === 'Escape') closeViewer();
      else if (event.key === 'ArrowLeft') showImage(neighbor(-1));
      else if (event.key === 'ArrowRight') showImage(neighbor(1));
      else if (event.key === 'Tab') {
        // Keep focus inside the viewer while it is open.
        const focusable = [...viewer.root.querySelectorAll('a[href], button')]
          .filter((element) => element.offsetParent !== null);
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
      }
    } else if (event.key === 'Escape' && body.classList.contains('content-active')) {
      hidePanels();
    }
  });

  // --- Start ----------------------------------------------------------------

  function followHash() {
    const image = readHash();
    update();
    if (image) {
      if (viewer.image) showImage(image); else openViewer(image);
    } else {
      closeViewer();
    }
  }

  // replaceState does not fire hashchange, so this only follows links and
  // addresses someone enters.
  window.addEventListener('hashchange', followHash);
  followHash();
  window.setTimeout(() => body.classList.remove('is-preload'), 100);
}());
