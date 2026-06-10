part of 'super_bomb_bloc.dart';

class SuperBombState extends Equatable {
  final List<BoomLevelModel> levels;
  final List<BoomLevelModel> videos;
  final BoomThemeModel? theme;
  final List<BoomRuleModel> rules;
  final BoomLevelModel? selectedLevel;
  final RequestState levelsState;
  final RequestState videosState;
  final RequestState themesState;
  final RequestState rulesState;
  final String? message;

  const SuperBombState({
    this.levels = const [],
    this.videos = const [],
    this.theme,
    this.rules = const [],
    this.selectedLevel,
    this.levelsState = RequestState.idle,
    this.videosState = RequestState.idle,
    this.themesState = RequestState.idle,
    this.rulesState = RequestState.idle,
    this.message,
  });

  SuperBombState copyWith({
    List<BoomLevelModel>? levels,
    List<BoomLevelModel>? videos,
    BoomThemeModel? theme,
    List<BoomRuleModel>? rules,
    BoomLevelModel? selectedLevel,
    RequestState? levelsState,
    RequestState? videosState,
    RequestState? themesState,
    RequestState? rulesState,
    String? message,
  }) {
    return SuperBombState(
      levels: levels ?? this.levels,
      videos: videos ?? this.videos,
      theme: theme ?? this.theme,
      rules: rules ?? this.rules,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      levelsState: levelsState ?? this.levelsState,
      videosState: videosState ?? this.videosState,
      themesState: themesState ?? this.themesState,
      rulesState: rulesState ?? this.rulesState,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        levels,
        videos,
        theme,
        rules,
        selectedLevel,
        levelsState,
        videosState,
        themesState,
        rulesState,
        message,
      ];
}
