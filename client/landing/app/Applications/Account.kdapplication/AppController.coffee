class AccountAppController extends AppController

  KD.registerAppClass this,
    name         : "Account"
    route        : "/:name?/Account"
    behavior     : "hideTabs"
    hiddenHandle : yes
    navItem      :
      title      : "Account"
      path       : "/Account"
      order      : 70
      type       : "account"
      loggedIn   : yes

  constructor:(options={},data)->

    options.view = new KDView cssClass : "content-page"

    super options, data

    @itemsOrdered = []

  loadView:(mainView)->
    items = @items

    # SET UP VIEWS
    @navController = new AccountSideBarController
      domId : "account-nav"
    navView = @navController.getView()

    @wrapperController = new AccountContentWrapperController
      view    : wrapperView = new KDView
        domId : "account-content-wrapper"

    #ADD CONTENT SECTIONS
    @navController.sectionControllers = []
    @wrapperController.sectionLists = []
    for own sectionKey, section of items
      do =>
        @navController.sectionControllers.push lc = new AccountNavigationController
          wrapper     : no
          scrollView  : no
          viewOptions :
            type      : sectionKey
            cssClass  : "settings-menu"
          itemClass   : AccountNavigationLink
        , section

        navView.addSubView lc.getView()
        navView.addSubView new KDCustomHTMLView tagName : "hr"

        lc.getView().on 'ItemWasAdded', (view, index)=>
          view.on "click", =>
            @wrapperController.scrollTo @indexOfItem view.getData()

      for own itemKey,item of section.items
        @itemsOrdered.push item
        section.id = sectionKey
        wrapperView.addSubView wrapper = new AccountListWrapper
          cssClass : "settings-list-wrapper #{__utils.slugify(item.title)}"
        ,{item,section}
        @wrapperController.sectionLists.push wrapper

    navView.setPartial """
      <div class="kdview kdlistview">
      <h3>Legal</h3>
      <div class="kdview kdlistitemview newpage"><a href="/tos.html" target="_blank">Terms of service <span class="icon new-page"></span></a></div>
      <div class="kdview kdlistitemview newpage"><a href="/privacy.html" target="_blank">Privacy policy <span class="icon new-page"></span></a></div>
      </div>
      """

    # SET UP SPLIT VIEW AND TOGGLERS
    @split = split = new SplitView
      domId     : "account-split-view"
      sizes     : [188,null]
      views     : [navView,wrapperView]
      minimums  : [null,null]
      resizable : yes
    mainView.addSubView split

    [panel0, panel1] = split.panels

    panel1.on "scroll", (event)=> @contentScrolled panel1, event

    panel0.addSubView @leftToggler = new KDView
      cssClass : "account-sidebar-toggler left"
      click    : => @toggleSidebar show:no

    split.addSubView @rightToggler = new KDView
      cssClass : "account-sidebar-toggler right hidden"
      click    : => @toggleSidebar show:yes

    @_windowDidResize()
    KD.getSingleton("windowController").registerWindowResizeListener @

    @utils.wait => @split._windowDidResize()

  contentScrolled:(pubInst,event)->
    @__lastScrollTop or= 0
    newScrollTop = pubInst.$().scrollTop()
    return if @__lastScrollTop is newScrollTop

    topIndex = @wrapperController.getSectionIndexForScrollOffset newScrollTop
    @navController.setActiveNavItem topIndex

    @__lastScrollTop = newScrollTop

  _windowDidResize:->
    lastWrapper = @wrapperController.sectionLists[@wrapperController.sectionLists.length-1]
    lastWrapper.setHeight @navController.getView().getHeight()

  showReferrerTooltip:(options)->

    {linkView, top, left, arrowMargin} = options

    referrerCode  = KD.whoami().profile.nickname
    shareUrl      = "#{location.origin}/?r=#{referrerCode}"

    contextMenu   = new JContextMenu
      cssClass    : "activity-share-popup"
      type        : "activity-share"
      delegate    : linkView
      x           : linkView.getX() - left
      y           : linkView.getY() - top
      arrow       :
        placement : "bottom"
        margin    : arrowMargin
      lazyLoad    : yes
    , customView  : new SharePopup {
        url       : shareUrl
        shortenURL: false
        twitter   :
          text    : "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{shareUrl}"
        linkedin  :
          title   : "Join me @koding!"
          text    : "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{shareUrl}"
      }

    new KDOverlayView
      parent      : KD.getSingleton("mainView").mainTabView.activePane
      transparent : yes


  toggleSidebar:(options)->
    {show} = options
    controller = @

    split = @split
    if show
      split.showPanel 0, ->
        controller.rightToggler.hide()
        controller.leftToggler.show()
    else
      split.hidePanel 0, ->
        controller.rightToggler.show()
        controller.leftToggler.hide()

  indexOfItem:(item)->
    @itemsOrdered.indexOf item

  items :
    personal :
      title : "Personal"
      items : [
        { title : "Login & Email",        listHeader: "Email & username",           listType: "username",       id : 10,      parentId : null }
        { title : "Password & Security",  listHeader: "Password & Security",        listType: "security",       id : 20,      parentId : null }
        { title : "E-mail Notifications", listHeader: "E-mail Notifications",       listType: "emailNotifications", id : 22,  parentId : null }
        { title : "Linked accounts",      listHeader: "Your Linked Accounts",       listType: "linkedAccounts", id : 30,      parentId : null }
        { title : "Referrals",            listHeader: "Referrals ",                 listType: "referralSystem", id : 40,      parentId : null }
      ]
    billing :
      title : "Billing"
      items : [
        { title : "Payment methods",      listHeader: "Your Payment Methods",       listType: "methods",        id : 10,      parentId : null }
        { title : "Your subscriptions",   listHeader: "Your Active Subscriptions",  listType: "subscriptions",  id : 20,      parentId : null }
        { title : "Billing history",      listHeader: "Billing History",            listType: "history",        id : 30,      parentId : null }
      ]
    develop :
      title : "Develop"
      items : [
        { title : "SSH keys",             listHeader: "Your SSH Keys",              listType: "keys",           id : 5,       parentId : null }
        { title : "Koding Keys",          listHeader: "Your Koding Keys",           listType: "kodingKeys",     id : 10,      parentId : null }
      ]
      # kites :
      #   title : "Kites"
      #   items : [
      #     { title : "My Kites",             listHeader: "Your own Kites",             listType: "myKiteList",     id : 10,      parentId : null }
      #     { title : "All Kites",            listHeader: "Your 3rd Party Kites",       listType: "kiteList",       id : 20,      parentId : null }
      #   ]

class AccountSideBarController extends KDViewController
  constructor:(options, data)->
    options.view = new KDView domId : options.domId
    super options, data

  loadView:(mainView)->
    allNavItems = []
    for controller in @sectionControllers
      allNavItems = allNavItems.concat controller.itemsOrdered

    @allNavItems = allNavItems

    @setActiveNavItem 0

  setActiveNavItem:(index)->
    sectionControllers = @sectionControllers
    totalIndex    = 0
    controllerIndex = 0
    while index >= totalIndex
      activeNavController = sectionControllers[controllerIndex]
      controllerIndex++
      totalIndex += activeNavController.itemsOrdered.length

    activeNavItem = @allNavItems[index]

    @unselectAllNavItems activeNavController
    activeNavController.selectItem activeNavItem

  unselectAllNavItems:(clickedController)->
    for controller in @sectionControllers
      controller.deselectAllItems() unless clickedController is controller


class AccountContentWrapperController extends KDViewController

  getSectionIndexForScrollOffset:(offset)->

    sectionIndex = 0
    while @sectionLists[sectionIndex + 1]?.$().position().top <= offset
      sectionIndex++
    sectionIndex

  scrollTo:(index)->

    itemToBeScrolled = @sectionLists[index]
    scrollToValue    = itemToBeScrolled.$().position().top
    @getView().parent.$().animate scrollTop : scrollToValue, 300


class AccountNavigationController extends KDListViewController

  loadView:(mainView)->

    mainView.setPartial "<h3>#{@getData().title}</h3>"
    super
