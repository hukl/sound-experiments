-module(sine_generator).

-compile(export_all).

-define(BIT_DEPTH,   16).   % Bit
-define(FREQUENCY,   300). % Hertz
-define(DURATION,    10).  % in Seconds
-define(SAMPLE_RATE, 44100).




calculate_sample(CurrentSample) ->
    BitDepthValue = round(math:pow(2, ?BIT_DEPTH)/2) - 10, %padding
    BitDepthValue * math:sin(
        2 * math:pi() * ?FREQUENCY * (CurrentSample/?SAMPLE_RATE)
    ).


generate_period_samples() ->
    SampleSeq = lists:reverse(lists:seq(0, ?SAMPLE_RATE-1)),
    SampleFun = fun(Sample, SampleList) ->
        SampleVal    = round(calculate_sample(Sample)),
        SampleValBin = << SampleVal:?BIT_DEPTH/integer-signed-little >>,

        [SampleValBin | SampleList]
    end,

    list_to_binary(
        lists:foldl(SampleFun, [], SampleSeq)
    ).


generate_pcm_data() ->
    SampleFun = fun(_, Samples) ->
        [generate_period_samples() | Samples]
    end,

    Data = lists:reverse(
        lists:foldl(SampleFun, [], lists:seq(1, ?DURATION))
    ),

    list_to_binary(Data).


generate_wave_file() ->
    Data            = generate_pcm_data(),
    ChunkId         = <<"RIFF">>,
    DataSize        = byte_size(Data),
    ChunkSize       = (36+DataSize),
    Format          = <<"WAVE">>,
    SubChunk1Id     = <<"fmt ">>,
    SubChunk1Size   = 16,
    AudioFormat     = 1,            % PCM
    NumChannels     = 1,            % Mono
    SampleRate      = ?SAMPLE_RATE, % *kHz
    BitsPerSample   = ?BIT_DEPTH,
    ByteRate        = SampleRate * NumChannels * round(BitsPerSample/8),
    BlockAlign      = NumChannels * round(BitsPerSample/8),
    SubChunk2Id     = <<"data">>,
    SubChunk2Size   = DataSize,


    WaveBytes = <<
        ChunkId/binary,
        ChunkSize:32/integer-little,
        Format/binary,
        SubChunk1Id/binary,
        SubChunk1Size:32/integer-little,
        AudioFormat:16/integer-little,
        NumChannels:16/integer-little,
        SampleRate:32/integer-little,
        ByteRate:32/integer-little,
        BlockAlign:16/integer-little,
        BitsPerSample:16/integer-little,
        SubChunk2Id/binary,
        SubChunk2Size:32/integer-little,
        Data/binary
    >>,

    io:format("~p~n", [WaveBytes]),

    file:write_file("/tmp/sine.wav", WaveBytes).








