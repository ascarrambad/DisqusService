Pod::Spec.new do |s|
    s.name = 'DisqusService'
    s.version = '1.0.1'
    s.summary = 'Wrapper for Disqus APIs written in Swift'

    s.homepage = 'https://github.com/ascarrambad/DisqusService'
    s.license = { :type => 'MIT', :file => 'LICENSE' }
    s.author = { 'ascarrambad' => 'matteoriva@me.com' }
    s.social_media_url = 'http://about.me/teoriva'

    s.ios.deployment_target = '8.0'

    s.source = { :git => 'https://github.com/ascarrambad/DisqusService.git', :tag => s.version }
    s.source_files = 'Sources/*.swift'
end
