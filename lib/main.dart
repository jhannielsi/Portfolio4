import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyScreen(),
    );
  }
}

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movie List")),
      body: const MyHttpWidget(),
    );
  }
}

class MyHttpWidget extends StatefulWidget {
  const MyHttpWidget({super.key});

  final movieUri =
      'https://cloud.thws.de/public.php/dav/files/i5Bcxj6eESPETkE/';

  @override
  State<MyHttpWidget> createState() => _MyHttpWidgetState();
}

class _MyHttpWidgetState extends State<MyHttpWidget> {
  List<Movie> movies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies().then((m) {
      setState(() {
        isLoading = false;
        movies = m;
      });
    });
  }

  Future<List<Movie>> _loadMovies() async {
    await Future.delayed(const Duration(seconds: 2));
    final response = await http.get(Uri.parse(widget.movieUri));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => Movie.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (movies.isEmpty) {
      return const Center(child: Text("No movies found"));
    }

    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieListItem(movie: movies[index]);
      },
    );
  }
}

class MovieListItem extends StatelessWidget {
  final Movie movie;
  const MovieListItem({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image:
                  movie.imageUrl.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(movie.imageUrl),
                        fit: BoxFit.cover,
                      )
                      : null,
              color: movie.imageUrl.isEmpty ? Colors.grey[300] : null,
            ),
            child:
                movie.imageUrl.isEmpty
                    ? const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text("Director: ${movie.director}"),
                const SizedBox(height: 8),
                Text(
                  movie.plot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Movie {
  final String title;
  final String director;
  final String plot;
  final String imageUrl;

  Movie({
    required this.title,
    required this.director,
    required this.plot,
    required this.imageUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final images = json['Images'] as List<dynamic>?;
    String selectedImage = json['Poster'] ?? '';

    if (images != null && images.isNotEmpty) {
      final random = Random();
      final startIndex = random.nextInt(images.length);

      for (int i = 0; i < images.length; i++) {
        final index = (startIndex + i) % images.length;

        String candidate = images[index] as String;
        candidate = candidate.replaceAll('\n', '').replaceAll(' ', '');
        final lower = candidate.toLowerCase();

        if (candidate.isNotEmpty &&
            !lower.contains('notfound') &&
            !lower.contains('404')) {
          selectedImage = candidate;
          break;
        }
      }
    }

    return Movie(
      title: json['Title'] ?? 'No Title',
      director: json['Director'] ?? 'Unknown',
      plot: json['Plot'] ?? 'No description available.',
      imageUrl: selectedImage,
    );
  }
}
