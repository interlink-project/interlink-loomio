import EventBus from '@/shared/services/event_bus'
import AppConfig from '@/shared/services/app_config'

export default
  methods:
    openAuthModal: (preventClose = false, loginMode = null) ->
      # ADDED TO AUTHENTICATE DIRECTLY WITH THE SPECIFIED PROVIDER
      hint = this.$route.query.login_hint
      providers = AppConfig.identityProviders.filter (provider) -> provider.name == hint
      if providers.length > 0 
        provider = providers[0]
        window.location = "#{provider.href}?back_to=#{window.location.href.substring(0, window.location.href.indexOf('?'))}"
        return

      EventBus.$emit('openModal', component: 'AuthModal', props: {preventClose: preventClose, loginMode: loginMode} )
