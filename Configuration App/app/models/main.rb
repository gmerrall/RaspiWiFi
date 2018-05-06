class Main < ActiveRecord::Base

	def self.scan_wifi_networks
    ap_list = %x{sudo iwlist scan}.split('Cell')
    ap_array = Array.new

    ap_list.each{|ap_grouping|
      ssid = ''

      ap_grouping.split("\n").each{|line|
        if line.include?('ESSID')
            ssid = line[27..-2]
        end
      }

      unless ssid == ''
        ap_array << ssid
      end
    }

    ap_array
	end

  def self.create_wpa_supplicant(ssid, wifi_key)
		temp_conf_file = File.new('../tmp/wpa_supplicant.conf.tmp', 'w')

		temp_conf_file.puts 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev'
		temp_conf_file.puts 'update_config=1'
		temp_conf_file.puts
		temp_conf_file.puts 'network={'
		temp_conf_file.puts '	ssid="' + ssid + '"'

		if wifi_key == 'open'
			temp_conf_file.puts '	key_mgmt=NONE'
		else
			temp_conf_file.puts '	psk="' + wifi_key + '"'
		end

		temp_conf_file.puts '}'

		temp_conf_file.close

		system('sudo cp -r ../tmp/wpa_supplicant.conf.tmp /etc/wpa_supplicant/wpa_supplicant.conf')
		system('rm ../tmp/wpa_supplicant.conf.tmp')
	end

  def self.set_ap_client_mode
	raspiwifi_path = find_raspiwifi_path()
	lsb_release_string = %x{lsb_release -a}

	if lsb_release_string.include?('jessie')
		system ('sudo cp -r ' + raspiwifi_path + '/Reset\ Device/static_files/interfaces.apclient /etc/network/interfaces')
	elsif lsb_release_string.include?('stretch')
		system ('sudo rm /etc/network/interfaces')
	end

    system ('rm /etc/cron.raspiwifi/aphost_bootstrapper')
    system ('sudo cp -r ' + raspiwifi_path + '/Reset\ Device/static_files/apclient_bootstrapper /etc/cron.raspiwifi/')
    system ('sudo cp -r ' + raspiwifi_path + '/Reset\ Device/static_files/isc-dhcp-server.apclient /etc/default/isc-dhcp-server')
    system ('sudo reboot')
  end

  def self.find_raspiwifi_path
		raspiwifi_path = File.dirname(__FILE__)[0..-30]

		raspiwifi_path
  end

end
