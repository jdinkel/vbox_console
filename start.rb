#!/usr/bin/env ruby

require "rubygems"
require "highline/import"

## should probably use "if $stdout.isatty" to make sure it is being run
## interactively

#Class VBoxMenuControl
#end

def clear_screen
  system "clear"
  print $/
end

def trim_names(vm_list)
  vm_list.map do |vm|
    /".+"/.match(vm).to_s[1...-1]
  end
end

def refresh_transition
  clear_screen
  print $/
  3.times do
    print '# '
    STDOUT.flush # or put "STDOUT.sync = true" at beginning of script
    sleep 0.1
  end
  print '#'
  clear_screen
end

def start_vm(vm_name)
  ## nohup su vbox -c "VBoxHeadless -s \"$1\" -n -m $2 -o pass" > /dev/null &
  ##vm_vnc_port = 5902
  #ask
  #`nohup su vbox -c \"VBoxHeadless -s \\"#{vm_name}\\" -n -m #{vm_vnc_port} -o pass\" > /dev/null &`

  vnc_port = ask("What port to use for the vnc service? ", Integer) { |q| q.in = 5901..5999 }.to_s
  `nohup su vbox -c \"VBoxHeadless -s \\"#{vm_name}\\" -n -m #{vnc_port} -o pass\" > /dev/null &`

  #clear_screen
  #puts 'not implemented yet'
  4.times do refresh_transition end
end

def get_used_vnc
  `ps a | grep VBoxHeadless`
end

def machine_states
  all = `su vbox -c 'VBoxManage -q list vms'`.split($/)
  running = `su vbox -c 'VBoxManage -q list runningvms'`.split($/)
  stopped = all - running
  stopped = trim_names(stopped).sort
  running = trim_names(running).sort

  return { :running => running, :stopped => stopped }
end

def is_running?(vm)
  all = machine_states
  running = false
  running = true if all[:running].include?(vm)
  return running
end

def show_vm_menu(vm)

  clear_screen
  back = false

  while back == false

    choose do |menu|
      menu.prompt = 'Choose an action: '
      menu.character = true

      menu.choice :'go back' do back = true end
      menu.choice :'refresh menu' do refresh_transition end

      unless is_running?(vm)
        menu.choice :'start virtual machine' do start_vm(vm) end
      end

    end
  end
  clear_screen
end

############################################################################
### Main Program                                                         ###
############################################################################

# check that we are running as root
if `whoami`.chomp == "root"

  clear_screen
  exit = false
  while exit == false

    choose do |menu|
      menu.prompt = "Choose a machine: "

      menu.choice :exit do exit = true end
      menu.choice :refresh do refresh_transition end

      all_vms = machine_states
      stopped_vms = all_vms[:stopped]
      running_vms = all_vms[:running]

      running_vms.each do |vm_name|
        menu.choice "<%= color('#{vm_name}', :green, :bold) %>" do show_vm_menu(vm_name) end
      end
      stopped_vms.each do |vm_name|
        menu.choice "<%= color('#{vm_name}', :red, :bold) %>" do show_vm_menu(vm_name) end
      end

      menu.character = true
    end
  end
  clear_screen

else
  say "You must be root to run this."
end

#choose do |menu|
#  menu.prompt = "Choose an action:  "

#  menu.choice = :show do show_running_vms end
#  menu.choice = :"Show running virtual machines" do show_running_vms end
#  menu.choice = :exit do say "goodbye." end
#end