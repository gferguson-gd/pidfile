require File.expand_path(File.join('..', 'lib', 'pidfile'), File.dirname(__FILE__))

PID_DIR = File.expand_path(File.join('var', 'run'), File.dirname(__FILE__))
PID_FILE = 'rspec.pid'
ALT_PID_FILE = 'foo.pid'

describe PidFile do
  before(:each) do
    PidFile::DEFAULT_OPTIONS[:piddir] = PID_DIR
    @pidfile = PidFile.new
  end

  after(:each) do
    @pidfile.release
  end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
  # Builder Tests
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

  it 'should set defaults upon instantiation' do
    expect(@pidfile.pidfile).to eq(PID_FILE)
    expect(@pidfile.piddir).to eq(PID_DIR)
    expect(@pidfile.pidpath).to eq(File.join(PID_DIR, PID_FILE))
  end

  it 'should secure pidfiles left behind and recycle them for itself' do
    @pidfile.release

    fakepid = 99999999 # absurd number
    File.write(@pidfile.pidpath, fakepid)
    pf = PidFile.new

    expect(PidFile.pid(pf.pidpath)).to eq(Process.pid)
    expect(pf).to be_an_instance_of(PidFile)
    expect(pf.pid).not_to eq(fakepid)
    expect(pf.pid).to be_a_kind_of(Integer)

    pf.release
  end

  it 'should create a pid file upon instantiation' do
    expect(File.exists?(@pidfile.pidpath)).to be true
  end

  it 'should create a pidfile containing same PID as process' do
    expect(@pidfile.pid).to eq(Process.pid)
  end

  it 'should know if pidfile exists or not' do
    expect(@pidfile.pidfile_exists?).to be true
    @pidfile.release
    expect(@pidfile.pidfile_exists?).to be false
  end

  it 'should be able to tell if a process is running' do
    expect(@pidfile.alive?).to be true
  end

  it 'should remove the pidfile when the calling application exits' do
    fork do
      exit
    end

    expect(PidFile.pidfile_exists?).to be false
  end

  it 'should raise an error if a pidfile already exists' do
    expect(lambda { PidFile.new }).to raise_error
  end

  it 'should know if a process exists or not - Class method' do
    expect(PidFile.running?( File.join(PID_DIR, PID_FILE)     )).to be true
    expect(PidFile.running?( File.join(PID_DIR, ALT_PID_FILE) )).to be false
  end

  it 'should know if it is running - Class method' do
    # screw with the defaults...
    old_pidfile = PidFile::DEFAULT_OPTIONS[:pidfile]
    PidFile::DEFAULT_OPTIONS[:piddir] = PID_DIR
    PidFile::DEFAULT_OPTIONS[:pidfile] = ALT_PID_FILE

    pf = PidFile.new
    expect(PidFile.running?).to be true
    pf.release
    expect(PidFile.running?).to be false

    # unscrew with the defaults...
    PidFile::DEFAULT_OPTIONS[:pidfile] = old_pidfile
  end

  it 'should know if it is alive or not' do
    expect(@pidfile.alive?).to be true
    @pidfile.release
    expect(@pidfile.alive?).to be false
  end

  it 'should remove pidfile and set pid to nil when released' do
    @pidfile.release
    expect(@pidfile.pidfile_exists?).to be false
    expect(@pidfile.pid).to be_nil
  end

  it 'should give a Time value for locktime' do
    expect(@pidfile.locktime).to be_an_instance_of(Time)
  end
end
