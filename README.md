Overview

Diurnus is a mobile application designed to help users gradually expand their vocabulary through daily exposure to uncommon and interesting English words.

The name Diurnus is a play on the word Diurnal, a term used to describe something that occurs during the daytime or follows a daily cycle. The name was chosen to reflect the application’s core purpose: delivering a new word every day and encouraging small, consistent moments of learning.

Rather than overwhelming users with quizzes, flashcards, or large volumes of content, Diurnus focuses on a single carefully selected word each day. The goal is to encourage consistent learning through small, meaningful interactions that can be completed in seconds.

The application was developed using React and Android, supported by a custom API responsible for delivering daily vocabulary content and associated metadata.

While the Android implementation was completed, additional platform development was not pursued.

⸻

Project Goals

The project aimed to:

* Encourage daily vocabulary growth.
* Create a frictionless learning experience.
* Reinforce learning through definitions, usage examples, and synonyms.
* Promote consistency through home screen widgets.
* Explore cross-platform development workflows.
* Build an educational application centred around habit formation rather than intensive study.

Rather than requiring users to actively open the application, Diurnus was designed to bring learning directly to the user through widgets and automatically refreshed daily content.

⸻

Features

Daily Vocabulary Experience

A new word is delivered every day through a custom API.

The application is intentionally designed around a single-screen experience, allowing users to quickly explore a new word without navigating through multiple menus or content pages.

Each daily word contains three information tabs:

Definition

Provides a clear explanation of the word’s meaning.

Usage

Demonstrates how the word can be used naturally within a sentence or real-world context.

Synonym

Provides related words to help users connect new vocabulary with language they already understand.

Together, these three views help users move beyond simple memorisation and develop a broader understanding of how the word can be recognised and applied in everyday language.

Home Screen Widgets

The application supports multiple widget sizes, allowing users to display daily vocabulary directly on their Android home screen.

This approach encourages passive learning by exposing users to new words throughout the day without requiring them to actively launch the application.

Daily Content Delivery

Vocabulary content is delivered through a custom-built API developed specifically for the project.

This allows new words and supporting content to be introduced without requiring application updates, separating content management from application deployment.

Minimalist User Experience

The interface was intentionally designed around a single purpose:

Present the daily word clearly and elegantly.

By reducing unnecessary navigation and distractions, the application focuses entirely on the learning experience.

Responsive Widget Design

Multiple widget layouts were created to support different Android home screen configurations while maintaining a consistent visual identity.

⸻

Technical Challenges

Daily Content Infrastructure

A custom API was developed to manage and distribute daily vocabulary content.

This separated content management from application deployment and allowed the vocabulary database to evolve independently of the application itself.

Widget Development

A major focus of the project was creating a reliable widget experience capable of displaying dynamic content outside of the main application.

The challenge was ensuring consistency between the application and widget content while supporting multiple widget sizes and Android configurations.

Cross-Platform Architecture

The project was originally designed with broader platform support in mind.

While only the Android implementation was completed, the architecture was designed to support future expansion.

Content Design

Selecting appropriate words required balancing:

* Educational value
* Difficulty
* Memorability
* Practical usefulness

The objective was to introduce interesting vocabulary without making the experience feel academic or intimidating.

⸻

Technology Stack

* Kotlin
* React
* Android SDK
* Custom REST API
* Android Home Screen Widgets

⸻

Design Philosophy

Diurnus was built around the idea that small amounts of learning performed consistently can be more effective than occasional intensive study.

Rather than overwhelming users with large quantities of content, the application focuses on a single carefully selected word each day.

By combining definitions, usage examples, and synonyms within a simple interface, the goal is to help users understand not only what a word means, but how it relates to words they already know and how it can be used in practice.

The visual design reflects this philosophy through a calm, library-inspired aesthetic intended to evoke curiosity, learning, and discovery.

⸻

My Contributions

This project was developed independently from concept through to completion of the Android implementation.

Responsibilities included:

* Product Design
* UI/UX Design
* Android Development
* React Development
* API Design & Development
* Widget Development
* Branding & Visual Design
* Testing & Deployment

⸻

Lessons Learned

This project provided experience across frontend, backend, and content-driven application development.

Key areas of growth included:

* API-driven architectures
* Widget development
* Cross-platform planning
* Educational product design
* Habit-forming user experiences
* Content management strategies

Perhaps most importantly, the project reinforced the value of simplicity and demonstrated how a focused product can often provide a better user experience than one overloaded with features.

⸻

Future Improvements

* Additional language support
* Word history and favourites
* Pronunciation audio
* Learning streaks
* Expanded widget customisation
* Offline content caching
* Cross-platform deployment

⸻

Screenshots
