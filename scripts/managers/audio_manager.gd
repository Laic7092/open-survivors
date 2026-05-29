extends Node

# AudioManager — autoload singleton
# Generates procedural SFX and BGM, plays them through a player pool.

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}

const SFX_PLAYER_COUNT = 6
const SAMPLE_RATE = 22050


func _ready():
	var _pa_ready = Time.get_ticks_msec()
	process_mode = PROCESS_MODE_WHEN_PAUSED

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.volume_db = -12.0
	add_child(bgm_player)

	for i in range(SFX_PLAYER_COUNT):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer" + str(i)
		p.volume_db = -3.0
		add_child(p)
		sfx_players.append(p)

	sounds = _generate_sounds()
	print("[perf] AudioManager._ready() TOTAL: %d ms" % (Time.get_ticks_msec() - _pa_ready))


# ── Public API ──────────────────────────────────────────────

func play_sfx(name: String):
	if not sounds.has(name):
		return
	var stream: AudioStreamWAV = sounds[name]
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# All busy — reuse the first one (cuts off previous)
	sfx_players[0].stream = stream
	sfx_players[0].play()


func play_bgm(stream: AudioStream):
	bgm_player.stream = stream
	bgm_player.play()


func stop_bgm():
	bgm_player.stop()


func set_bgm_volume(db: float):
	bgm_player.volume_db = db


# ── Sound generation ────────────────────────────────────────

func _generate_sounds() -> Dictionary:
	var _pa0 = Time.get_ticks_msec()
	return {
		"menu_select": _mk_tone(440, 0.08, 0.25),
		"menu_confirm": _mk_tone(660, 0.12, 0.3),

		"enemy_die": _mk_sweep(400, 120, 0.2, 0.3),
		"enemy_shoot": _mk_sweep(800, 300, 0.12, 0.2),
		"player_hurt": _mk_tone(150, 0.15, 0.4),

		"level_up": _mk_arpeggio([523, 659, 784], 0.25, 0.3),
		"evolution": _mk_arpeggio([523, 659, 784, 1047], 0.4, 0.35),

		"pickup_chicken": _mk_tone(880, 0.1, 0.2),
		"pickup_gold": _mk_tone(660, 0.08, 0.15),
		"pickup_rosary": _mk_sweep(600, 1400, 0.35, 0.35),
		"pickup_vacuum": _mk_sweep(300, 900, 0.3, 0.25),

		"game_over": _mk_sweep(500, 80, 0.8, 0.4),

		# Weapon sounds
		"wpn_whip": _mk_sweep(400, 600, 0.08, 0.18),
		"wpn_wand": _mk_tone(1200, 0.05, 0.15),
		"wpn_garlic": _mk_sweep(200, 100, 0.15, 0.20),
		"wpn_knife": _mk_sweep(800, 1200, 0.06, 0.15),
		"wpn_axe": _mk_sweep(300, 150, 0.12, 0.22),
		"wpn_fire": _mk_sweep(400, 800, 0.15, 0.20),
		"wpn_evo": _mk_arpeggio([660, 880, 1100], 0.2, 0.25),
		"wpn_cross": _mk_sweep(500, 900, 0.12, 0.2),
		"wpn_heaven": _mk_arpeggio([880, 1100, 1320], 0.2, 0.3),
		"wpn_bible": _mk_tone(880, 0.08, 0.2),
		"wpn_water": _mk_sweep(200, 400, 0.15, 0.25),
		"wpn_runetracer": _mk_sweep(600, 1200, 0.1, 0.18),
		"wpn_nofuture": _mk_sweep(300, 1400, 0.2, 0.3),
		"wpn_lightning": _mk_noise(0.08, 0.15),
		"wpn_bounce": _mk_tone(600, 0.03, 0.08),
		"player_revive": _mk_arpeggio([660, 880, 1100, 1320], 0.3, 0.4),

		"bgm_menu": _mk_bgm_loop(8.0),
		"bgm_game": _mk_bgm_loop(10.0),
		"bgm_alt": _mk_bgm_loop_alt(12.0),
	}
	print("[perf] AudioManager._generate_sounds TOTAL: %d ms" % (Time.get_ticks_msec() - _pa0))


# Build a simple generative BGM loop: ambient pads + subtle pulse
func _mk_bgm_loop(length_sec: float) -> AudioStreamWAV:
	var _pmb0 = Time.get_ticks_msec()
	var frames = int(SAMPLE_RATE * length_sec)
	var data = PackedByteArray()
	data.resize(frames * 2)

	# Two slowly shifting chords underneath
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		# Chord: root + fifth + octave
		var amp = 0.0
		amp += sin(2.0 * PI * 110.0 * t) * 0.08          # A2
		amp += sin(2.0 * PI * 164.81 * t) * 0.06          # E3
		amp += sin(2.0 * PI * 220.0 * t) * 0.05           # A3
		# Slow LFO for movement
		var lfo = sin(2.0 * PI * 0.25 * t) * 0.5 + 0.5
		amp += sin(2.0 * PI * 110.0 * 2.0 * t) * 0.03 * lfo
		# Subtle pulse
		var pulse = (sin(2.0 * PI * 2.0 * t) * 0.5 + 0.5)
		amp += sin(2.0 * PI * 220.0 * t) * 0.04 * pulse
		# Fade in/out at loop boundaries
		var envelope = 1.0
		if t < 0.1:
			envelope = t / 0.1
		elif t > length_sec - 0.1:
			envelope = (length_sec - t) / 0.1
		amp *= envelope * 0.7

		var val = int(clamp(amp * 16384, -16384, 16383))
		data.encode_s16(i * 2, val)

	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	print("[perf] _mk_bgm_loop(%.1fs): %d ms" % [length_sec, Time.get_ticks_msec() - _pmb0])
	return wav


# Alternate BGM — minor key, darker mood
func _mk_bgm_loop_alt(length_sec: float) -> AudioStreamWAV:
	var _pmb1 = Time.get_ticks_msec()
	var frames = int(SAMPLE_RATE * length_sec)
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var amp = 0.0
		# Minor chord: root + minor third + fifth
		amp += sin(2.0 * PI * 110.0 * t) * 0.07          # A2
		amp += sin(2.0 * PI * 130.81 * t) * 0.05          # C3 (minor third)
		amp += sin(2.0 * PI * 164.81 * t) * 0.04          # E3
		amp += sin(2.0 * PI * 220.0 * t) * 0.03           # A3 (octave)
		# Slow LFO
		var lfo = sin(2.0 * PI * 0.3 * t) * 0.4 + 0.6
		amp += sin(2.0 * PI * 130.81 * 2.0 * t) * 0.04 * lfo
		# Pulsing bass
		var pulse = (sin(2.0 * PI * 2.5 * t) * 0.5 + 0.5)
		amp += sin(2.0 * PI * 55.0 * t) * 0.06 * pulse
		# Envelope
		var envelope = 1.0
		if t < 0.1:
			envelope = t / 0.1
		elif t > length_sec - 0.1:
			envelope = (length_sec - t) / 0.1
		amp *= envelope * 0.6
		var val = int(clamp(amp * 16384, -16384, 16383))
		data.encode_s16(i * 2, val)
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	print("[perf] _mk_bgm_loop_alt(%.1fs): %d ms" % [length_sec, Time.get_ticks_msec() - _pmb1])
	return wav


# Simple sine-wave tone, optional descending pitch
func _mk_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var frames = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var f = freq
		var sample = sin(2.0 * PI * f * t) * volume
		var env = 1.0
		if t < 0.01:
			env = t / 0.01
		elif t > duration - 0.02:
			env = (duration - t) / 0.02
		var val = int(clamp(sample * env * 16384, -16384, 16383))
		data.encode_s16(i * 2, val)
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	return wav


# White noise burst
func _mk_noise(duration: float, volume: float) -> AudioStreamWAV:
	var frames = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = 1.0
		if t < 0.005:
			env = t / 0.005
		elif t > duration - 0.01:
			env = (duration - t) / 0.01
		var sample = randf_range(-1.0, 1.0) * volume * env
		var val = int(clamp(sample * 16384, -16384, 16383))
		data.encode_s16(i * 2, val)
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	return wav


# Frequency sweep
func _mk_sweep(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var frames = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var f = freq_start + (freq_end - freq_start) * (t / duration)
		var sample = sin(2.0 * PI * f * t) * volume
		var env = 1.0
		if t < 0.01:
			env = t / 0.01
		elif t > duration - 0.02:
			env = (duration - t) / 0.02
		var val = int(clamp(sample * env * 16384, -16384, 16383))
		data.encode_s16(i * 2, val)
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	return wav


# Quick ascending arpeggio (several notes in sequence)
func _mk_arpeggio(notes: Array[float], duration: float, volume: float) -> AudioStreamWAV:
	var note_len = duration / notes.size()
	var frames = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var note_idx = min(int(t / note_len), notes.size() - 1)
		var note_t = t - note_idx * note_len
		var f = notes[note_idx]
		var sample = sin(2.0 * PI * f * fmod(note_t * 4.0, 1.0)) * volume
		var env = 1.0
		if note_t < 0.01:
			env = note_t / 0.01
		elif note_t > note_len - 0.02:
			env = (note_len - note_t) / 0.02
		var val = int(clamp(sample * env * 16384, -16384, 16383))
		data.encode_s16(i * 2, val)
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	return wav
