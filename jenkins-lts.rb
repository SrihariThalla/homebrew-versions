class JenkinsLts < Formula
  desc "Extendable open-source CI server"
  homepage "https://jenkins.io/index.html#stable"
  url "http://mirrors.jenkins-ci.org/war-stable/2.32.3/jenkins.war"
  sha256 "3eb599dd78ecf00e5f177ec5c4b1ba4274be4e5f63236da6ac92401a66fa91e8"

  bottle :unneeded

  depends_on :java => "1.7+"

  conflicts_with "jenkins",
    :because => "both use the same data directory: $HOME/.jenkins"

  def install
    system "jar", "xvf", "jenkins.war"
    libexec.install Dir["jenkins.war", "WEB-INF/jenkins-cli.jar"]
    bin.write_jar_script libexec/"jenkins.war", "jenkins-lts"
    bin.write_jar_script libexec/"jenkins-cli.jar", "jenkins-lts-cli"
  end

  def caveats; <<-EOS.undent
    Note: When using launchctl the port will be 8080.
    EOS
  end

  plist_options :manual => "jenkins-lts"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>/usr/bin/java</string>
          <string>-Dmail.smtp.starttls.enable=true</string>
          <string>-jar</string>
          <string>#{opt_libexec}/jenkins.war</string>
          <string>--httpListenAddress=127.0.0.1</string>
          <string>--httpPort=8080</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
    EOS
  end

  test do
    ENV["JENKINS_HOME"] = testpath
    ENV.append "_JAVA_OPTIONS", "-Djava.io.tmpdir=#{testpath}"

    pid = fork do
      exec "#{bin}/jenkins-lts"
    end
    sleep 60

    begin
      output = shell_output("curl localhost:8080/")
      assert_match(/Welcome to Jenkins!|Unlock Jenkins|Authentication required/, output)
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
