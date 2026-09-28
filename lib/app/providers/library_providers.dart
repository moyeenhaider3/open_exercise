// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_bloc/flutter_bloc.dart';

import '../dependencies.dart';

/// Per-feature BlocProvider list for Library features.
/// Filled by plan 03-05; each feature Bloc reads GymStateCubit via context.read in create.
List<BlocProvider> libraryBlocProviders(AppDependencies deps) => <BlocProvider>[];
