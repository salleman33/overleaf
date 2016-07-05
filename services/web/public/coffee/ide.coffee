define [
	"base"
	"ide/file-tree/FileTreeManager"
	"ide/connection/ConnectionManager"
	"ide/editor/EditorManager"
	"ide/online-users/OnlineUsersManager"
	"ide/track-changes/TrackChangesManager"
	"ide/permissions/PermissionsManager"
	"ide/pdf/PdfManager"
	"ide/binary-files/BinaryFilesManager"
	"ide/references/ReferencesManager"
	"ide/settings/index"
	"ide/share/index"
	"ide/chat/index"
	"ide/clone/index"
	"ide/hotkeys/index"
	"ide/wordcount/index"
	"ide/directives/layout"
	"ide/services/ide"
	"__IDE_CLIENTSIDE_INCLUDES__"
	"analytics/AbTestingManager"
	"directives/focus"
	"directives/fineUpload"
	"directives/scroll"
	"directives/onEnter"
	"directives/stopPropagation"
	"directives/rightClick"
	"services/queued-http"
	"filters/formatDate"
	"main/event"
	"main/account-upgrade"
], (
	App
	FileTreeManager
	ConnectionManager
	EditorManager
	OnlineUsersManager
	TrackChangesManager
	PermissionsManager
	PdfManager
	BinaryFilesManager
	ReferencesManager
) ->

	App.controller "IdeController", ($scope, $timeout, ide, localStorage, event_tracking) ->
		# Don't freak out if we're already in an apply callback
		$scope.$originalApply = $scope.$apply
		$scope.$apply = (fn = () ->) ->
			phase = @$root.$$phase
			if (phase == '$apply' || phase == '$digest')
				fn()
			else
				this.$originalApply(fn);

		$scope.state = {
			loading: true
			load_progress: 40
			error: null
		}
		$scope.ui = {
			leftMenuShown: false
			view: "editor"
			chatOpen: false
			pdfLayout: 'sideBySide'
		}
		$scope.user = window.user
		$scope.settings = window.userSettings
		$scope.anonymous = window.anonymous

		$scope.chat = {}

		# Tracking code.
		$scope.$watch "ui.view", (newView, oldView) ->
			event_tracking.send "ide-open-view-#{ newView }" if newView?

		$scope.$watch "ui.chatOpen", (isOpen) ->
			event_tracking.send "ide-open-chat" if isOpen

		$scope.$watch "ui.leftMenuShown", (isOpen) ->
			event_tracking.send "ide-open-left-menu" if isOpen
		# End of tracking code.

		window._ide = ide

		ide.project_id = $scope.project_id = window.project_id
		ide.$scope = $scope

		ide.referencesSearchManager = new ReferencesManager(ide, $scope)
		ide.connectionManager = new ConnectionManager(ide, $scope)
		ide.fileTreeManager = new FileTreeManager(ide, $scope)
		ide.editorManager = new EditorManager(ide, $scope)
		ide.onlineUsersManager = new OnlineUsersManager(ide, $scope)
		ide.trackChangesManager = new TrackChangesManager(ide, $scope)
		ide.pdfManager = new PdfManager(ide, $scope)
		ide.permissionsManager = new PermissionsManager(ide, $scope)
		ide.binaryFilesManager = new BinaryFilesManager(ide, $scope)

		inited = false
		$scope.$on "project:joined", () ->
			return if inited
			inited = true
			if $scope?.project?.deletedByExternalDataSource
				ide.showGenericMessageModal("Project Renamed or Deleted", """
					This project has either been renamed or deleted by an external data source such as Dropbox.
					We don't want to delete your data on ShareLaTeX, so this project still contains your history and collaborators.
					If the project has been renamed please look in your project list for a new project under the new name.
				""")

		DARK_THEMES = [
			"ambiance", "chaos", "clouds_midnight", "cobalt", "idle_fingers",
			"merbivore", "merbivore_soft", "mono_industrial", "monokai",
			"pastel_on_dark", "solarized_dark", "terminal", "tomorrow_night",
			"tomorrow_night_blue", "tomorrow_night_bright", "tomorrow_night_eighties",
			"twilight", "vibrant_ink"
		]
		$scope.darkTheme = false
		$scope.$watch "settings.theme", (theme) ->
			if theme in DARK_THEMES
				$scope.darkTheme = true
			else
				$scope.darkTheme = false

		ide.localStorage = localStorage

		ide.browserIsSafari = false
		try
			userAgent = navigator.userAgent
			ide.browserIsSafari = (
				userAgent &&
				userAgent.match(/.*Safari\/.*/) &&
				!userAgent.match(/.*Chrome\/.*/) &&
				!userAgent.match(/.*Chromium\/.*/)
			)
		catch err
			console.error err

		# User can append ?ft=somefeature to url to activate a feature toggle
		ide.featureToggle = location?.search?.match(/^\?ft=(\w+)$/)?[1]


	angular.bootstrap(document.body, ["SharelatexApp"])
