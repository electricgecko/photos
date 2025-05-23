console.log('(photos)');

document.addEventListener('DOMContentLoaded', () => {
  const
    photos    = document.querySelectorAll('main figure'),
    lastPhoto = document.querySelector('main figure:last-of-type'),
    main      = document.querySelector('body > main'),
    aside     = document.querySelector('body > main > aside'),
    body      = document.querySelector('body'),
    footer    = document.querySelector('footer');
  
  let
    init      = true;
    hintSeen  = false;
  
  const showingThumbs = (() => {
    return body.classList.contains('small');
  });
  
  // load settings from local storage 
  if (localStorage.getItem('mmbg') == 'invert') {
      body.classList.add('invert');
  }
    
  if (localStorage.getItem('mmsz') == 'small') {
      body.classList.remove('large');
      main.classList.remove('large');
      body.classList.add('small');
      main.classList.add('small');
      aside.classList.add('hidden');
  }
  
  if (localStorage.getItem('mmhint') == 'true') {
      hintSeen = true;
  }

  // helper to get img element
  const getPhoto = ((wrapper) => {
    return wrapper.firstElementChild;
  });
  
  // track images & lazy load
  const galleryObserver = new IntersectionObserver((els, observer) => {
    els.forEach((el) => {
      if (el.isIntersecting && el.target.nodeName == 'FIGURE') {
                  
        const 
          img = getPhoto(el.target),
          template = el.target.querySelector('.caption'),
          caption = template.content.cloneNode(true);
        
        if (!init || hintSeen) {
          aside.innerHTML = '';
        } else {
          init = false;
          localStorage.setItem('mmhint', 'true');
        }
        
        aside.appendChild(caption);     
        aside.classList.remove('invisible');  
                
        if (showingThumbs()) {
          if (img.src != img.dataset.lowres) { img.src = img.dataset.lowres; }
        } else {
          if (img.src != img.dataset.highres) { img.src = img.dataset.highres; }
        }
        
        img.addEventListener('load', () => {
          if (!el.target.classList.contains('loaded')) {
            el.target.classList.remove('invisible');
            if (!showingThumbs()) { 
              el.target.classList.add('loaded');
            }
          }
        });
      }
      
      if (el.isIntersecting && (el.target == footer)) {
        aside.classList.add('invisible');
      }
    });
  });
  
  photos.forEach((photo) => {
    galleryObserver.observe(photo);
  });
  
  galleryObserver.observe(footer);
  
  // zoom photos  
  const loadHighresPhoto = async photo => {
    img = getPhoto(photo);
    img.src = img.dataset.highres;
  }
  
  const unloadThumbs = async () => {
    photos.forEach((photo) => {
      getPhoto(photo).removeAttribute('src');
    });
  }
   
  const toggleZoom = ((target) => {
    if (!target) { 
      target = photos[0];
    };
    
    if (!showingThumbs()) {  
      body.classList.remove('large');
      main.classList.remove('large');
      body.classList.add('small');
      main.classList.add('small');
      aside.classList.add('hidden');
      localStorage.setItem('mmsz', 'small');    
      window.scrollTo(0,0);
        
      } else {
        if (!target.classList.contains('loaded')) {
          target.classList.add('invisible');
        }
        
        aside.innerHTML = '';
        aside.appendChild(target.querySelector('.caption').content.cloneNode(true));  

        loadHighresPhoto(target).then(() => {
          body.classList.remove('small');
          main.classList.remove('small');
          body.classList.add('large');
          main.classList.add('large');
          aside.classList.remove('hidden');
          aside.classList.remove('invisible');
          localStorage.removeItem('mmsz');
          target.scrollIntoView();
        })     
    }
  });
 
  // load large photo into display
  photos.forEach((photo) => {
    getPhoto(photo).addEventListener('click', () => {
      toggleZoom(photo);
    });
  })
  
  // keyboard controls
  window.addEventListener('keyup', (e) => {
    if (e.which == 73) {
      body.classList.toggle('invert');
      if (body.classList.contains('invert')) {
        localStorage.setItem('mmbg', 'invert');
      } else {
        localStorage.setItem('mmbg', 'default');
      }
    }
  });  
});