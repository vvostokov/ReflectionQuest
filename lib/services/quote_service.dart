import 'dart:math';

class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});
}

class QuoteService {
  static final QuoteService _instance = QuoteService._internal();
  factory QuoteService() => _instance;
  QuoteService._internal();

  final List<Quote> _quotes = const [
    Quote(text: "Единственный способ делать великие дела – любить то, что вы делаете.", author: "Стив Джобс"),
    Quote(text: "Успех - это способность идти от поражения к поражению, не теряя энтузиазма.", author: "Уинстон Черчилль"),
    Quote(text: "Ваше время ограничено, не тратьте его, живя чужой жизнью.", author: "Стив Джобс"),
    Quote(text: "Стремитесь не к успеху, а к ценностям, которые он дает.", author: "Альберт Эйнштейн"),
    Quote(text: "Лучший способ предсказать будущее – создать его.", author: "Питер Друкер"),
    Quote(text: "Через двадцать лет вы будете больше разочарованы теми вещами, которые вы не делали, чем теми, которые вы сделали.", author: "Марк Твен"),
    Quote(text: "Начинайте с того, что необходимо, затем делайте то, что возможно, и внезапно вы обнаружите, что делаете невозможное.", author: "Франциск Ассизский"),
    Quote(text: "Путешествие в тысячу миль начинается с одного шага.", author: "Лао-цзы"),
    Quote(text: "Верь, что можешь, и ты уже на полпути к цели.", author: "Теодор Рузвельт"),
    Quote(text: "Препятствия – это те пугающие вещи, которые вы видите, когда отводите взгляд от своей цели.", author: "Генри Форд"),
  ];

  Quote getDailyQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  List<Quote> getShuffledQuotes() {
    final shuffledList = List<Quote>.from(_quotes);
    shuffledList.shuffle(Random());
    return shuffledList;
  }
}