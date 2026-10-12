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
  // Wallpapers added within this many days carry a New badge.
  const NEW_DAYS = 30;
  const DAY = 24 * 60 * 60 * 1000;
  const FAVORITES_KEY = 'favorites';

  const body = document.body;
  const main = document.getElementById('main');
  const collection = JSON.parse(document.getElementById('collection').textContent);
  const numbers = new Intl.NumberFormat('en-US');
  // Dates are whole days in UTC, so show them in UTC to keep the same day.
  const dates = new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeZone: 'UTC' });
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
        addedTime: Date.parse(`${image.added}T00:00:00Z`),
      };
    })
    .sort((a, b) =>
      formatOrder.indexOf(a.format) - formatOrder.indexOf(b.format)
      || a.category.localeCompare(b.category)
      || a.name.localeCompare(b.name));
  // The sort is stable, so each day's additions stay in A to Z order.
  const newest = images.slice().sort((a, b) => b.addedTime - a.addedTime);
  // The archive's first upload is not news, even while it is recent.
  const firstUpload = Math.min(...images.map((image) => image.addedTime));
  images.forEach((image) => {
    image.isNew = image.addedTime > firstUpload && Date.now() - image.addedTime < NEW_DAYS * DAY;
  });
  const categories = [...new Set(images.map((image) => image.category))]
    .sort((a, b) => categoryLabel(a).localeCompare(categoryLabel(b)));

  document.querySelectorAll('[data-repository-link]').forEach((link) => {
    link.href = `https://github.com/${collection.repository}${link.dataset.repositoryLink}`;
  });

  // --- Favorites ------------------------------------------------------------

  // Favorites are paths kept in this browser's storage. Storage can be
  // missing or blocked, as in some private windows; favorites then last only
  // until the page closes.
  function readFavorites() {
    try {
      const saved = JSON.parse(localStorage.getItem(FAVORITES_KEY) || '[]');
      return new Set(Array.isArray(saved) ? saved.filter((path) => typeof path === 'string') : []);
    } catch (error) {
      console.warn('Favorites could not be read:', error);
      return new Set();
    }
  }

  function saveFavorites() {
    try {
      localStorage.setItem(FAVORITES_KEY, JSON.stringify([...favorites]));
    } catch (error) {
      console.warn('Favorites could not be saved:', error);
    }
  }

  let favorites = readFavorites();
  const isFavorite = (image) => favorites.has(image.path);

  function showFavorite(button, image) {
    const favorite = isFavorite(image);
    button.classList.toggle('solid', favorite);
    button.setAttribute('aria-pressed', String(favorite));
    button.title = favorite ? 'Remove from favorites' : 'Add to favorites';
  }

  function toggleFavorite(image) {
    if (isFavorite(image)) favorites.delete(image.path); else favorites.add(image.path);
    saveFavorites();
    showFavorite(image.favoriteButton, image);
    if (viewer.image === image) showFavorite(viewer.favorite, image);
    update();
  }

  // Keep other tabs of the gallery in step.
  window.addEventListener('storage', (event) => {
    if (event.key !== FAVORITES_KEY) return;
    favorites = readFavorites();
    images.forEach((image) => showFavorite(image.favoriteButton, image));
    if (viewer.image) showFavorite(viewer.favorite, viewer.image);
    update();
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

    const favorite = document.createElement('button');
    favorite.type = 'button';
    favorite.className = 'favorite icon fa-heart';
    favorite.setAttribute('aria-label', `Favorite ${image.title}`);
    favorite.addEventListener('click', () => toggleFavorite(image));
    showFavorite(favorite, image);

    article.append(link, heading, favorite);
    if (image.isNew) {
      const badge = document.createElement('span');
      badge.className = 'badge';
      badge.textContent = 'New';
      article.append(badge);
    }
    image.article = article;
    image.favoriteButton = favorite;
    fragment.append(article);
    if (thumbnails) thumbnails.observe(article); else loadThumbnail(article);
  });
  main.append(fragment);

  // --- Filters --------------------------------------------------------------

  // An empty order follows the filters: shuffled while nothing narrows the
  // collection, so each visit opens on a different mix, and A to Z once a
  // format, category, search, or favorites is chosen. Choosing an order
  // overrides that until the filters change again.
  const ORDERS = [
    { id: 'shuffle', label: 'Shuffle' },
    { id: 'newest', label: 'Newest' },
    { id: 'name', label: 'A to Z' },
  ];
  const state = { format: '', category: '', query: '', order: '', favorites: false };
  let visible = images;
  let shuffled = shuffle(images);
  let arranged = images;

  function shuffle(list) {
    const copy = list.slice();
    for (let i = copy.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
  }

  const filtered = () =>
    Boolean(state.format || state.category || state.query.trim() || state.favorites);
  const currentOrder = () => state.order || (filtered() ? 'name' : 'shuffle');

  const search = document.getElementById('search');
  const summary = document.getElementById('summary');
  const showResults = document.getElementById('show-results');
  const empty = document.getElementById('empty');
  const noFavorites = document.getElementById('no-favorites');

  function matches(image, ignore) {
    if (ignore !== 'favorites' && state.favorites && !isFavorite(image)) return false;
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
        state.order = '';
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

  const favoritesButtons = [
    { id: false, label: 'Everything' },
    { id: true, label: 'Favorites' },
  ].map((item) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.append(item.label);
    const count = document.createElement('span');
    count.className = 'count';
    button.append(count);
    button.addEventListener('click', () => {
      state.favorites = item.id;
      state.order = '';
      update({ scroll: true });
    });
    const entry = document.createElement('li');
    entry.append(button);
    document.getElementById('favorites-filters').append(entry);
    return { id: item.id, button, count };
  });

  // Shuffle again reshuffles, so it doubles as a "show me others" button.
  const orderButtons = ORDERS.map((item) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = item.label;
    button.addEventListener('click', () => {
      if (item.id === 'shuffle' && currentOrder() === 'shuffle') shuffled = shuffle(images);
      state.order = item.id;
      update({ scroll: true });
    });
    const entry = document.createElement('li');
    entry.append(button);
    document.getElementById('order-filters').append(entry);
    return { id: item.id, button };
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

  // Favorites stays selectable with none saved, so its empty view can explain
  // how to add some.
  function refreshFavoritesButtons() {
    const pool = images.filter((image) => matches(image, 'favorites'));
    favoritesButtons.forEach(({ id, button, count }) => {
      count.textContent = numbers.format(id ? pool.filter(isFavorite).length : pool.length);
      button.setAttribute('aria-pressed', String(state.favorites === id));
    });
  }

  function update({ scroll = false } = {}) {
    const order = currentOrder();
    const source = { shuffle: shuffled, newest, name: images }[order];
    // Moving the tiles is the costly part, so only do it when the order changes.
    if (arranged !== source) {
      main.append(...source.map((image) => image.article));
      arranged = source;
    }
    visible = source.filter((image) => matches(image));
    const shown = new Set(visible);
    images.forEach((image) => { image.article.hidden = !shown.has(image); });
    const noneSaved = state.favorites && favorites.size === 0;
    noFavorites.hidden = !noneSaved;
    empty.hidden = visible.length > 0 || noneSaved;

    refreshButtons(formatButtons, 'format');
    refreshButtons(categoryButtons, 'category');
    refreshFavoritesButtons();
    orderButtons.forEach(({ id, button }) => button.setAttribute('aria-pressed', String(order === id)));

    const noun = visible.length === 1 ? 'wallpaper' : 'wallpapers';
    const parts = [`${numbers.format(visible.length)} ${noun}`];
    if (state.favorites) parts.push('Favorites');
    if (state.format) parts.push(formatLabel(state.format));
    if (state.category) parts.push(categoryLabel(state.category));
    if (state.query.trim()) parts.push(`“${state.query.trim()}”`);
    if (order === 'shuffle') parts.push('Shuffled');
    if (order === 'newest') parts.push('Newest first');
    summary.textContent = parts.join(' · ');
    showResults.textContent = `Show ${numbers.format(visible.length)} ${noun}`;

    if (viewer.image) trimViewerList();
    writeHash();
    if (scroll) window.scrollTo(0, 0);
  }

  let searchTimer;
  search.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      state.query = search.value;
      state.order = '';
      update({ scroll: true });
    }, 150);
  });

  document.querySelectorAll('[data-reset]').forEach((link) => {
    link.addEventListener('click', (event) => {
      event.preventDefault();
      state.format = '';
      state.category = '';
      state.query = '';
      state.order = '';
      state.favorites = false;
      search.value = '';
      update({ scroll: true });
    });
  });

  // --- Address --------------------------------------------------------------

  // Filters, a chosen order, and the open wallpaper live in the URL's hash,
  // with favorites=1 for this browser's favorites,
  // such as #format=dual&category=space&view=wallpapers/dual/space/name.jpg,
  // so a view can be bookmarked or shared.
  function writeHash() {
    const params = new URLSearchParams();
    if (state.format) params.set('format', state.format);
    if (state.category) params.set('category', state.category);
    if (state.query.trim()) params.set('q', state.query.trim());
    if (state.order) params.set('order', state.order);
    if (state.favorites) params.set('favorites', '1');
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
    const order = params.get('order') || '';
    state.order = ORDERS.some((item) => item.id === order) ? order : '';
    state.favorites = params.get('favorites') === '1';
    search.value = state.query;
    return images.find((image) => image.path === params.get('view'));
  }

  // --- Panels ---------------------------------------------------------------

  // The template's sliding panels: a toggle is any link to the panel's id.
  // Closed panels only slide out of view, so they are inert to keep their
  // controls out of the tab order and the accessibility tree.
  const panels = [...document.querySelectorAll('.panel')];
  let panelOpener = null;

  function hidePanels() {
    // Focus left inside a closing panel would be lost once it is inert.
    const stranded = panels.some((panel) => panel.contains(document.activeElement));
    panels.forEach((panel) => {
      panel.classList.remove('active');
      panel.inert = true;
    });
    document.querySelectorAll('#header nav a').forEach((link) => link.classList.remove('active'));
    body.classList.remove('content-active');
    if (stranded) {
      if (panelOpener) panelOpener.focus({ preventScroll: true });
      else document.activeElement.blur();
    }
    panelOpener = null;
  }

  function showPanel(panel, opener) {
    hidePanels();
    panelOpener = opener;
    panel.inert = false;
    panel.classList.add('active');
    document.querySelectorAll(`#header nav a[href="#${panel.id}"]`)
      .forEach((link) => link.classList.add('active'));
    body.classList.add('content-active');
    // Panels follow every tile in the page, so focus moves into the open one
    // rather than leaving keyboard users to tab through the grid. Small
    // screens focus the panel itself to keep the on-screen keyboard closed.
    if (panel.id === 'browse' && !smallScreen.matches) search.focus({ preventScroll: true });
    else panel.focus({ preventScroll: true });
  }

  panels.forEach((panel) => {
    const closer = document.createElement('button');
    closer.type = 'button';
    closer.className = 'closer';
    closer.setAttribute('aria-label', 'Close');
    closer.addEventListener('click', hidePanels);
    panel.inert = true;
    panel.tabIndex = -1;
    panel.append(closer);
    panel.addEventListener('click', (event) => event.stopPropagation());

    document.querySelectorAll(`[href="#${panel.id}"]`).forEach((toggle) => {
      toggle.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        if (panel.classList.contains('active')) hidePanels(); else showPanel(panel, toggle);
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
    favorite: document.getElementById('viewer-favorite'),
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

  // Stepping through the viewer skips wallpapers that stop matching while it
  // is open, such as a removed favorite, but keeps the one on screen until
  // the viewer moves on.
  function trimViewerList() {
    viewer.list = viewer.list.filter((image) => image === viewer.image || matches(image));
    viewer.popup.classList.toggle('single', viewer.list.length < 2);
  }

  function showImage(image) {
    viewer.image = image;
    trimViewerList();
    viewer.popup.classList.add('loading');
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
      `Added ${dates.format(image.addedTime)}`,
    ].join(' · ');
    showFavorite(viewer.favorite, image);
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

  // The viewer steps through the wallpapers shown when it opens, or only the
  // one it opened on when that one is filtered out.
  const viewerListFor = (image) => (visible.includes(image) ? visible : [image]);

  function openViewer(image) {
    viewer.list = viewerListFor(image);
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
      returnFocusFromViewer(viewer.returnFocus);
    } else {
      document.activeElement.blur();
    }
  }

  // The opening tile can be hidden while the viewer is open, such as after
  // removing a favorite, so focus the nearest tile still shown, or Browse.
  function returnFocusFromViewer(opener) {
    if (opener.isConnected && opener.getClientRects().length > 0) {
      opener.focus({ preventScroll: true });
      return;
    }
    const tile = opener.closest('.thumb');
    let near = null;
    for (let next = tile && tile.nextElementSibling; next && !near; next = next.nextElementSibling) {
      if (!next.hidden) near = next;
    }
    for (let previous = tile && tile.previousElementSibling; previous && !near;
      previous = previous.previousElementSibling) {
      if (!previous.hidden) near = previous;
    }
    (near ? near.querySelector('.image') : document.querySelector('#header a[href="#browse"]')).focus();
  }

  viewer.root.querySelector('.closer').addEventListener('click', closeViewer);
  viewer.favorite.addEventListener('click', () => toggleFavorite(viewer.image));
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
      // A new address can change the filters as well as the wallpaper, so
      // the open viewer starts its steps over from what is now shown.
      if (viewer.image) {
        viewer.list = viewerListFor(image);
        showImage(image);
      } else {
        openViewer(image);
      }
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
