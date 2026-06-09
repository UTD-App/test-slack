console.log('✅ sidebar js loaded');

(function () {
    'use strict';

    let currentPopover = null;
    let popoverTimeout = null;

    let popoverStack = [];
    let treeIdCounter = 1;

    let currentTooltip = null;
    let tooltipTimeout = null;

    let openChildTimer = null;
    let closeChildTimer = null;

    function isSidebarCollapsed() {
        return document.body.classList.contains('sidebar-collapse');
    }

    function isRTL() {
        return document.documentElement.dir === 'rtl' || document.body.classList.contains('rtl');
    }

    function indexTrees() {
        document.querySelectorAll('.crs-tree').forEach(tree => {
            if (!tree.dataset.crsTreeId) {
                tree.dataset.crsTreeId = String(treeIdCounter++);
            }
        });
    }

    function animateSubmenuItems(submenu) {
        const items = submenu.querySelectorAll('.crs-item');

        items.forEach((item, index) => {
            item.style.opacity = '0';
            item.style.transform = 'translateX(-15px)';

            setTimeout(() => {
                item.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                item.style.opacity = '1';
                item.style.transform = 'translateX(0)';
            }, index * 120);
        });
    }

    function resetSubmenuItems(submenu) {
        const items = submenu.querySelectorAll('.crs-item');

        items.forEach((item) => {
            item.style.transition = 'none';
            item.style.opacity = '0';
            item.style.transform = 'translateX(-15px)';
        });
    }

    function closeOtherMenus(currentTree) {
        const currentLevel = getMenuLevel(currentTree);

        document.querySelectorAll('.crs-tree.crs-open').forEach(function (tree) {
            if (tree !== currentTree && getMenuLevel(tree) === currentLevel) {
                const submenu = tree.querySelector('.crs-submenu');
                const toggle = tree.querySelector('.crs-toggle');

                if (submenu) {
                    resetSubmenuItems(submenu);
                    submenu.style.maxHeight = submenu.scrollHeight + 'px';
                    void submenu.offsetHeight;
                    submenu.style.maxHeight = '0px';

                    submenu.addEventListener('transitionend', function _h() {
                        submenu.style.removeProperty('max-height');
                        submenu.removeEventListener('transitionend', _h);
                    });
                }

                tree.classList.remove('crs-open');
                if (toggle) {
                    toggle.setAttribute('aria-expanded', 'false');
                }
            }
        });
    }

    function getMenuLevel(tree) {
        let level = 0;
        let parent = tree.parentElement;

        while (parent) {
            if (parent.classList && parent.classList.contains('crs-submenu')) {
                level++;
            }
            parent = parent.parentElement;
        }

        return level;
    }

    function closeTooltip() {
        if (tooltipTimeout) {
            clearTimeout(tooltipTimeout);
            tooltipTimeout = null;
        }

        if (currentTooltip) {
            currentTooltip.classList.remove('show');
            const el = currentTooltip;
            currentTooltip = null;
            setTimeout(() => {
                if (el && el.parentNode) el.remove();
            }, 200);
        }
    }

    function createLeafTooltip(link) {
        closeTooltip();

        const titleEl = link.querySelector('.crs-title');
        if (!titleEl) return;

        const text = titleEl.textContent.trim();
        if (!text) return;

        const tip = document.createElement('div');
        tip.className = 'crs-tooltip';
        tip.textContent = text;

        document.body.appendChild(tip);

        const r = link.getBoundingClientRect();
        const tr = tip.getBoundingClientRect();
        const gap = 12;

        let top = r.top + (r.height / 2) - (tr.height / 2);

        let left;

        tip.classList.remove('from-left', 'from-right');

        const preferLeft = r.left > (window.innerWidth / 2);

        if (preferLeft) {
            left = r.left - tr.width - gap;
            tip.classList.add('from-right');
        } else {
            left = r.right + gap;
            tip.classList.add('from-left');
        }

        if (left < 10) {
            left = r.right + gap;
            tip.classList.remove('from-right');
            tip.classList.add('from-left');
        }
        if (left + tr.width > window.innerWidth - 10) {
            left = r.left - tr.width - gap;
            tip.classList.remove('from-left');
            tip.classList.add('from-right');
        }

        if (top < 10) top = 10;
        if (top + tr.height > window.innerHeight - 10) top = window.innerHeight - tr.height - 10;

        tip.style.left = left + 'px';
        tip.style.top = top + 'px';

        setTimeout(() => tip.classList.add('show'), 10);
        currentTooltip = tip;
    }

    function closePopoversFrom(level) {
        if (openChildTimer) {
            clearTimeout(openChildTimer);
            openChildTimer = null;
        }
        if (closeChildTimer) {
            clearTimeout(closeChildTimer);
            closeChildTimer = null;
        }

        for (let i = popoverStack.length - 1; i >= 0; i--) {
            const p = popoverStack[i];
            if (p.level >= level) {
                p.el.classList.remove('show');
                const el = p.el;
                setTimeout(() => {
                    if (el && el.parentNode) el.remove();
                }, 250);
                popoverStack.pop();
            }
        }
        currentPopover = popoverStack.length ? popoverStack[popoverStack.length - 1].el : null;
    }

    function closeAllPopovers() {
        closePopoversFrom(0);
        closeTooltip();
    }

    function resolveTreeFromToggle(toggle) {
        const targetId = toggle && toggle.dataset ? toggle.dataset.targetTreeId : null;
        if (targetId) {
            const safe = (window.CSS && CSS.escape) ? CSS.escape(targetId) : targetId;
            return document.querySelector(`.crs-tree[data-crs-tree-id="${safe}"]`);
        }
        return toggle.closest('.crs-tree');
    }

    function buildPopoverItemsFromSubmenu(popover, submenu) {
        const children = Array.from(submenu.children);

        children.forEach(child => {
            if (child.classList && child.classList.contains('crs-tree')) {
                const nestedToggle = child.querySelector(':scope > .crs-toggle');
                if (!nestedToggle) return;

                const li = document.createElement('li');
                li.className = 'crs-item';

                const clonedToggle = nestedToggle.cloneNode(true);

                if (child.dataset && child.dataset.crsTreeId) {
                    clonedToggle.dataset.targetTreeId = child.dataset.crsTreeId;
                }

                li.appendChild(clonedToggle);
                popover.appendChild(li);
                return;
            }

            popover.appendChild(child.cloneNode(true));
        });
    }

    function createPopover(toggle, level = 0) {
        closeTooltip();
        closePopoversFrom(level);

        const tree = resolveTreeFromToggle(toggle);
        if (!tree) return;

        const submenu = tree.querySelector(':scope > .crs-submenu');
        if (!submenu) return;

        const popover = document.createElement('div');
        popover.className = 'crs-popover';
        popover.dataset.level = String(level);

        buildPopoverItemsFromSubmenu(popover, submenu);
        document.body.appendChild(popover);

        const anchorRect = toggle.getBoundingClientRect();
        const popoverRect = popover.getBoundingClientRect();
        const gap = 12;

        let top = anchorRect.top + (anchorRect.height / 2) - (popoverRect.height / 2);

        let left;

        popover.classList.remove('from-left', 'from-right');

        const preferLeft = anchorRect.left > (window.innerWidth / 2);

        if (preferLeft) {
            left = anchorRect.left - popoverRect.width - gap;
            popover.classList.add('from-right');
        } else {
            left = anchorRect.right + gap;
            popover.classList.add('from-left');
        }

        if (left < 10) {
            left = anchorRect.right + gap;
            popover.classList.remove('from-right');
        }
        if (left + popoverRect.width > window.innerWidth - 10) {
            left = anchorRect.left - popoverRect.width - gap;
            popover.classList.add('from-right');
        }

        if (top < 10) top = 10;
        if (top + popoverRect.height > window.innerHeight - 10) {
            top = window.innerHeight - popoverRect.height - 10;
        }

        popover.style.left = left + 'px';
        popover.style.top = top + 'px';

        setTimeout(() => {
            popover.classList.add('show');
        }, 10);

        popoverStack.push({ el: popover, level });
        currentPopover = popover;

        popover.querySelectorAll('.crs-link').forEach(link => {
            link.addEventListener('click', (e) => {
                const isProxyToggle = link.classList.contains('crs-toggle') && !!link.dataset.targetTreeId;

                if (isProxyToggle) {
                    e.preventDefault();
                    createPopover(link, level + 1);
                    return;
                }

                closeAllPopovers();
            });
        });

        popover.addEventListener('mouseenter', handlePopoverHover);
        popover.addEventListener('mouseleave', handlePopoverHover);
    }

    function handleToggleClick(e) {
        const toggle = e.target.closest('.crs-toggle');
        if (!toggle) return;

        e.preventDefault();

        const tree = toggle.closest('.crs-tree');
        if (!tree) return;

        const submenu = tree.querySelector('.crs-submenu');
        if (!submenu) return;

        const isOpen = tree.classList.contains('crs-open');

        if (isSidebarCollapsed()) {
            if (isOpen) {
                closeAllPopovers();
            } else {
                createPopover(toggle, 0);
            }
            tree.classList.toggle('crs-open');
            toggle.setAttribute('aria-expanded', isOpen ? 'false' : 'true');
        } else {
            closeAllPopovers();

            if (isOpen) {
                resetSubmenuItems(submenu);
                submenu.style.maxHeight = submenu.scrollHeight + 'px';
                void submenu.offsetHeight;
                submenu.style.maxHeight = '0px';
                tree.classList.remove('crs-open');
                toggle.setAttribute('aria-expanded', 'false');

                submenu.addEventListener('transitionend', function _h() {
                    submenu.style.removeProperty('max-height');
                    submenu.removeEventListener('transitionend', _h);
                });
            } else {
                closeOtherMenus(tree);

                submenu.style.maxHeight = submenu.scrollHeight + 'px';
                tree.classList.add('crs-open');
                toggle.setAttribute('aria-expanded', 'true');

                animateSubmenuItems(submenu);

                submenu.addEventListener('transitionend', function _k() {
                    submenu.style.maxHeight = 'none';
                    submenu.removeEventListener('transitionend', _k);
                });
            }
        }
    }

    function handleMenuItemHover(e) {
        // Guard against non-element targets
        if (!e.target || typeof e.target.closest !== 'function') return;
        
        const link = e.target.closest('.crs-link') || e.target.closest('.crs-item')?.querySelector('.crs-link');
        if (!link) return;

        const inPopover = !!link.closest('.crs-popover');

        if (e.type === 'mouseenter' || e.type === 'focus') {
            if (e.relatedTarget && link.contains(e.relatedTarget)) return;

            if (isSidebarCollapsed()) {
                const isToggle = link.classList.contains('crs-toggle');

                if (inPopover && isToggle && link.dataset.targetTreeId) {
                    closeTooltip();

                    if (openChildTimer) clearTimeout(openChildTimer);
                    if (closeChildTimer) clearTimeout(closeChildTimer);

                    const parentPopover = link.closest('.crs-popover');
                    const parentLevel = parentPopover ? parseInt(parentPopover.dataset.level || '0', 10) : 0;

                    openChildTimer = setTimeout(() => {
                        if (isSidebarCollapsed()) createPopover(link, parentLevel + 1);
                    }, 80);

                    return;
                }

                if (!inPopover && isToggle) {
                    closeTooltip();

                    if (popoverTimeout) clearTimeout(popoverTimeout);

                    popoverTimeout = setTimeout(() => {
                        if (isSidebarCollapsed()) createPopover(link, 0);
                    }, 300);

                    return;
                }

                if (!inPopover && !isToggle) {
                    if (tooltipTimeout) clearTimeout(tooltipTimeout);
                    tooltipTimeout = setTimeout(() => {
                        if (isSidebarCollapsed()) createLeafTooltip(link);
                    }, 0);
                    return;
                }
            } else {
                closeAllPopovers();
            }
        }

        if (e.type === 'mouseleave' || e.type === 'blur') {
            if (popoverTimeout) clearTimeout(popoverTimeout);
            if (tooltipTimeout) clearTimeout(tooltipTimeout);

            closeTooltip();

            if (inPopover) {
                const parentPopover = link.closest('.crs-popover');
                const parentLevel = parentPopover ? parseInt(parentPopover.dataset.level || '0', 10) : 0;

                if (parentPopover && e.relatedTarget && parentPopover.contains(e.relatedTarget)) {
                    return;
                }

                if (openChildTimer) clearTimeout(openChildTimer);

                if (closeChildTimer) clearTimeout(closeChildTimer);
                closeChildTimer = setTimeout(() => {
                    const hoveringAny = popoverStack.some(p => p.el && p.el.matches(':hover'));
                    if (!hoveringAny) closeAllPopovers();
                    else closePopoversFrom(parentLevel + 1);
                }, 260);

                return;
            }

            setTimeout(() => {
                if (!currentPopover || !currentPopover.matches(':hover')) {
                    closeAllPopovers();
                }
            }, 100);
        }
    }

    function handlePopoverHover(e) {
        if (e.type === 'mouseenter') {
            if (popoverTimeout) clearTimeout(popoverTimeout);
            if (closeChildTimer) clearTimeout(closeChildTimer);
        } else if (e.type === 'mouseleave') {
            setTimeout(() => {
                const hoveringAny = popoverStack.some(p => p.el && p.el.matches(':hover'));
                if (!hoveringAny) closeAllPopovers();
            }, 140);
        }
    }

    document.addEventListener('mouseenter', handleMenuItemHover, true);
    document.addEventListener('mouseleave', handleMenuItemHover, true);
    document.addEventListener('focus', handleMenuItemHover, true);
    document.addEventListener('blur', handleMenuItemHover, true);

    document.addEventListener('click', handleToggleClick);

    document.addEventListener('click', (e) => {
        const isClickOnPopover = e.target.closest('.crs-popover');
        const isClickOnToggle = e.target.closest('.crs-toggle');

        if (!isClickOnPopover && !isClickOnToggle) {
            closeAllPopovers();
        }
    });

    function saveSidebarState() {
        const isCollapsed = isSidebarCollapsed();
        localStorage.setItem('sidebarCollapsed', isCollapsed);

        const contentWrapper = document.querySelector('.content-wrapper');
        if (contentWrapper) {
            if (isCollapsed) {
                contentWrapper.classList.add('content-wrapper-rtl');
            } else {
                contentWrapper.classList.remove('content-wrapper-rtl');
            }
        }
    }

    function restoreSidebarState() {
        const savedState = localStorage.getItem('sidebarCollapsed');
        if (savedState === 'true') {
            document.body.classList.add('sidebar-collapse');
        } else if (savedState === 'false') {
            document.body.classList.remove('sidebar-collapse');
        }

        const contentWrapper = document.querySelector('.content-wrapper');
        if (contentWrapper) {
            const isCollapsed = savedState === 'true';
            if (isCollapsed) {
                contentWrapper.classList.add('content-wrapper-rtl');
            } else {
                contentWrapper.classList.remove('content-wrapper-rtl');
            }
        }
    }


    let previouslyOpenMenus = []; // Store which menus were open before collapse

    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                const isCollapsed = document.body.classList.contains('sidebar-collapse');

                if (isCollapsed) {
                    // ✅ COLLAPSING: Save open menus, then close them
                    previouslyOpenMenus = [];

                    document.querySelectorAll('.crs-tree.crs-open').forEach(function(tree) {
                        // Save the tree ID so we can reopen later
                        const treeId = tree.dataset.crsTreeId || tree.dataset.crsId;
                        if (treeId) {
                            previouslyOpenMenus.push(treeId);
                        }

                        const submenu = tree.querySelector('.crs-submenu');
                        const toggle = tree.querySelector('.crs-toggle');

                        tree.classList.remove('crs-open');

                        if (submenu) {
                            submenu.style.maxHeight = '0px';
                            submenu.style.opacity = '0';
                            submenu.style.transform = 'translateY(-10px) scaleY(0.95)';
                        }

                        if (toggle) {
                            toggle.setAttribute('aria-expanded', 'false');
                        }
                    });

                    closeAllPopovers();

                } else {
                    // ✅ EXPANDING: Re-open the menus that were open before
                    // OR open the menu containing the active item

                    setTimeout(() => {
                        // First, try to open menus that were previously open
                        if (previouslyOpenMenus.length > 0) {
                            previouslyOpenMenus.forEach(function(treeId) {
                                const tree = document.querySelector(`.crs-tree[data-crs-tree-id="${treeId}"]`) ||
                                    document.querySelector(`.crs-tree[data-crs-id="${treeId}"]`);

                                if (tree) {
                                    openSubmenu(tree);
                                }
                            });
                        } else {
                            // If no previously open menus, open the one with active item
                            const activeLink = document.querySelector('.crs-link.active, .crs-item.active .crs-link');
                            if (activeLink) {
                                openParentMenus(activeLink);
                            }
                        }
                    }, 100);
                }

                saveSidebarState();
            }
        });
    });

// ✅ Add this helper function to open a submenu
    function openSubmenu(tree) {
        if (!tree || tree.classList.contains('crs-open')) return;

        const submenu = tree.querySelector(':scope > .crs-submenu');
        const toggle = tree.querySelector(':scope > .crs-toggle');

        if (!submenu) return;

        tree.classList.add('crs-open');

        if (toggle) {
            toggle.setAttribute('aria-expanded', 'true');
        }

        // Reset and animate
        submenu.style.opacity = '1';
        submenu.style.transform = 'translateY(0) scaleY(1)';
        submenu.style.maxHeight = submenu.scrollHeight + 'px';

        // Animate items
        animateSubmenuItems(submenu);

        // After animation, set to none for nested content
        setTimeout(() => {
            if (tree.classList.contains('crs-open')) {
                submenu.style.maxHeight = 'none';
            }
        }, 400);
    }

    function highlightActiveMenuItem() {
        const currentPath = window.location.pathname;
        const currentUrl = window.location.href;

        document.querySelectorAll('.crs-item.active').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelectorAll('.crs-link.active').forEach(link => {
            link.classList.remove('active');
        });

        const menuLinks = document.querySelectorAll('.crs-link.crs-leaf');

        let activeLink = null;
        let bestMatchLength = 0;

        menuLinks.forEach(link => {
            const href = link.getAttribute('href');
            if (!href || href === '#') return;

            try {
                const linkUrl = new URL(href, window.location.origin);
                const linkPath = linkUrl.pathname;

                const normalizedCurrentPath = currentPath.replace(/\/$/, '');
                const normalizedLinkPath = linkPath.replace(/\/$/, '');

                if (normalizedCurrentPath === normalizedLinkPath) {
                    if (linkPath.length > bestMatchLength) {
                        bestMatchLength = linkPath.length;
                        activeLink = link;
                    }
                }
                else if (normalizedLinkPath !== '' &&
                    normalizedLinkPath !== '/' &&
                    normalizedCurrentPath.startsWith(normalizedLinkPath + '/')) {
                    if (linkPath.length > bestMatchLength) {
                        bestMatchLength = linkPath.length;
                        activeLink = link;
                    }
                }
            } catch (e) {
                if (href && (currentUrl.includes(href) || currentPath.includes(href))) {
                    if (href.length > bestMatchLength) {
                        bestMatchLength = href.length;
                        activeLink = link;
                    }
                }
            }
        });

        if (activeLink) {
            const activeItem = activeLink.closest('.crs-item');
            if (activeItem) {
                activeItem.classList.add('active');
            }

            activeLink.classList.add('active');

            openParentMenus(activeLink);

            setTimeout(() => {
                activeLink.scrollIntoView({
                    behavior: 'smooth',
                    block: 'center',
                    inline: 'nearest'
                });
            }, 400);
        }
    }

    function openParentMenus(element) {
        let parent = element.closest('.crs-submenu');

        while (parent) {
            const tree = parent.closest('.crs-tree');

            if (tree) {
                tree.classList.add('crs-open');

                const toggle = tree.querySelector(':scope > .crs-toggle');
                if (toggle) {
                    toggle.setAttribute('aria-expanded', 'true');
                }

                parent.style.maxHeight = 'none';

                // ✅ REMOVE inline styles so CSS animation can work!
                const items = parent.querySelectorAll(':scope > .crs-item');
                items.forEach(item => {
                    item.style.removeProperty('opacity');
                    item.style.removeProperty('transform');
                    item.style.removeProperty('transition');
                });
            }

            const parentTree = tree ? tree.parentElement : null;
            parent = parentTree ? parentTree.closest('.crs-submenu') : null;
        }
    }

    window.addEventListener('DOMContentLoaded', function () {
        restoreSidebarState();

        observer.observe(document.body, {
            attributes: true,
            attributeFilter: ['class']
        });

        indexTrees();

        document.querySelectorAll('.crs-submenu').forEach(function (sm) {
            const tree = sm.closest('.crs-tree');
            if (!tree || !tree.classList.contains('crs-open')) {
                sm.style.maxHeight = '0px';
                resetSubmenuItems(sm);
            } else {
                sm.style.maxHeight = 'none';
            }
        });

        highlightActiveMenuItem();
    });


    window.addEventListener('popstate', function() {
        setTimeout(highlightActiveMenuItem, 100);
    });

    $(document).on('pjax:complete', function() {
        highlightActiveMenuItem();
    });

    document.addEventListener('turbolinks:load', function() {
        highlightActiveMenuItem();
    });

    document.addEventListener('click', function(e) {
        const link = e.target.closest('.crs-link.crs-leaf');
        if (link && link.href) {
            document.querySelectorAll('.crs-item.active').forEach(item => {
                item.classList.remove('active');
            });
            document.querySelectorAll('.crs-link.active').forEach(l => {
                l.classList.remove('active');
            });

            const item = link.closest('.crs-item');
            if (item) item.classList.add('active');
            link.classList.add('active');
        }
    });

    (function () {
        function isMobile() {
            return window.matchMedia('(max-width: 767px)').matches;
        }

        document.addEventListener('click', function (e) {
            const leaf = e.target.closest('a.crs-link.crs-leaf');
            if (!leaf) return;

            if (!isMobile()) return;

            if (e.defaultPrevented) return;
            if (e.button !== 0) return;
            if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
            if (leaf.target && leaf.target !== '_self') return;

            e.preventDefault();

            window.location.href = leaf.href;
        }, true);

        $(document).ready(function() {
            moment.defineLocale('ar', {
                months: 'يناير_فبراير_مارس_أبريل_مايو_يونيو_يوليو_أغسطس_سبتمبر_أكتوبر_نوفمبر_ديسمبر'.split('_'),
                monthsShort: 'يناير_فبراير_مارس_أبريل_مايو_يونيو_يوليو_أغسطس_سبتمبر_أكتوبر_نوفمبر_ديسمبر'.split('_'),
                weekdays: 'الأحد_الإثنين_الثلاثاء_الأربعاء_الخميس_الجمعة_السبت'.split('_'),
                weekdaysShort: 'أحد_إثنين_ثلاثاء_أربعاء_خميس_جمعة_سبت'.split('_'),
                weekdaysMin: 'ح_ن_ث_ر_خ_ج_س'.split('_'),
                longDateFormat: {
                    LT: 'HH:mm',
                    LTS: 'HH:mm:ss',
                    L: 'YYYY-MM-DD',
                    LL: 'D MMMM YYYY',
                    LLL: 'D MMMM YYYY HH:mm',
                    LLLL: 'dddd D MMMM YYYY HH:mm'
                },
                week: { dow: 6, doy: 12 },
                meridiem: function (hour) {
                    return hour < 12 ? 'ص' : 'م';
                }
            });
            moment.locale('ar');
        });
    })();
})();

// Debugbar screen tracking removed (2026-05-24)
// Reason: Production app was making 547 requests/day to /__debugbar/screen (404 errors)
// if (window.APP_ENV !== 'production') {
//     window.addEventListener('load', function () {
//         fetch('/__debugbar/screen', {
//             method: 'POST',
//             headers: {
//                 'Content-Type': 'application/json',
//                 'X-CSRF-TOKEN': document
//                     .querySelector('meta[name="csrf-token"]')
//                     ?.getAttribute('content')
//             },
//             body: JSON.stringify({
//                 width: window.innerWidth,
//                 height: window.innerHeight
//             })
//         });
//     });
// }
