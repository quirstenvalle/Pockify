# PocketWise Finances

Pockify – Smart Expense Tracker

Detailed and Structured Application Overview

    Application Overview

Pockify is a modern Flutter-based personal expense tracker designed to help users monitor their daily finances, stay within budget, and build healthier spending habits. Unlike traditional expense trackers that only record transactions, Pockify provides intelligent financial insights through a Wallet Health Score, Budget Buddy Alerts, and an Essential Spending Streak system.

The application's goal is to make budgeting simple, engaging, and motivating while helping users make smarter financial decisions.

    Objectives

The application aims to:

Help users easily record income and expenses.

Allow users to create personalized budgets.

Visualize spending through interactive charts.

Provide smart financial recommendations.

Encourage responsible spending through achievements and streaks.

Help users avoid overspending before it happens.

    Target Users

Pockify is designed for:

College students

Young professionals

Freelancers

Families managing household expenses

Anyone who wants better control over personal finances

    Core Features

A. User Authentication

Users can:

Register an account

Log in securely

Reset password

Log out

Authentication can be implemented using:

Firebase Authentication

Email & Password

B. Dashboard (Home Screen)

The dashboard serves as the financial overview.

Displays:

Current Balance

Monthly Income

Monthly Expenses

Remaining Budget

Wallet Health Score

Essential Spending Streak

Recent Transactions

Quick Add Expense button

Example Dashboard Layout:

Hello, John!

Current Balance ₱12,500

Wallet Health Score 84 / 100

Essential Spending Streak  6 Days

Income ₱20,000

Expenses ₱7,500

Remaining Budget ₱12,500

Recent Transactions

• Food ₱250 • Transport ₱80 • Grocery ₱900

C. Expense Management

Users can:

Add Expense

Information:

Amount

Category

Date

Notes

Payment Method (optional)

Edit Expense

Delete Expense

Search Expenses

Filter Expenses

Today

This Week

This Month

Custom Date

D. Income Management

Users can also record income.

Examples:

Salary

Allowance

Freelance

Business

Gifts

This provides a more accurate wallet balance.

    Budget Management

One of the primary features.

Users choose which categories they want budgets for.

Example Categories

Default Categories

Food

Transportation

Grocery

Shopping

Entertainment

Bills

Healthcare

Education

Savings

Others

Users can:

 Add Budget

Example:

Food Monthly Budget ₱5,000

 Edit Budget

 Delete Budget

Custom Categories

Besides default categories, users can create unlimited custom categories.

Example:

Gaming

Pet Expenses

Coffee

Photography

Investments

Each custom category can have:

Icon

Budget

Color (optional)

    Expense Visualization

One of the strongest features.

Pie Chart

Shows percentage spent by category.

Example:

Food 35%

Transportation 20%

Shopping 15%

Bills 18%

Others 12%

Bar Graph

Shows spending over time.

Example:

Week 1 ██████

Week 2 ██████████

Week 3 ████

Week 4 ████████

Monthly Trend Chart

Displays expenses across months.

January

February

March

April

Users can identify trends.

Budget Progress Bars

Each budget displays remaining funds.

Example

Food

████████░░

₱4,000 / ₱5,000

Transportation

█████░░░░░

₱1,500 / ₱4,000

    Special Feature #1

Smart Wallet Health Score

This is Pockify's signature feature.

Every day, the application calculates a financial score from 0–100 based on the user's financial habits.

Factors considered:

Budget adherence

Savings progress

Spending consistency

Frequency of unnecessary purchases

Income vs expenses

Budget completion

Example

Wallet Health Score

89 / 100

Status

Excellent

Health Levels

90–100

Excellent

75–89

Healthy

60–74

Fair

40–59

Needs Improvement

0–39

Critical

Personalized Recommendations

Instead of only showing a number, Pockify explains how to improve.

Examples:

You spent 40% less on dining this week. Great job!

Transportation expenses increased by 18%.

You exceeded your entertainment budget.

Try reducing coffee purchases by ₱200 this week.

Consider transferring ₱500 into savings.

These recommendations can be generated using simple rule-based logic rather than AI, making the feature easier to implement while still feeling "smart."

    Special Feature #2

Budget Buddy Alerts

Real-time notifications help prevent overspending.

Examples

When 80% of budget is reached

Food Budget

₱4,000 of ₱5,000 used.

Only ₱1,000 remaining.

When 100% is reached

You have exceeded your Shopping Budget.

Smart Suggestions

Pockify analyzes recent spending and gives practical recommendations.

Examples

Instead of

You spent ₱250 on coffee.

It says

You've bought coffee 5 times this week.

Making coffee at home twice next week could save approximately ₱300.

Or

Transportation costs increased.

Walking short distances could reduce this week's expenses.

These suggestions are based on recent spending frequency and category totals, without requiring external data or complex AI.

    Special Feature #3

Essential Spending Streak

Unlike apps that reward users for spending less overall, Pockify encourages responsible spending by recognizing essential expenses.

Essential Categories

Grocery

Transportation

Bills

Education

Healthcare

Work Expenses

If a day's recorded expenses are only from these essential categories, the user extends their streak.

Example

 Essential Spending Streak

8 Days

Achievements

Users unlock badges such as:

 Smart Starter – 3-day streak

 Budget Keeper – 7-day streak

 Wise Spender – 14-day streak

 Financial Master – 30-day streak

The streak resets when a non-essential expense is recorded.

    Additional Features (Simple but Unique)

A. Spending Insights

Weekly summaries such as:

Biggest spending category

Highest single expense

Total saved compared to last week

Average daily spending

B. Monthly Financial Report

At the end of every month, generate a summary including:

Total income

Total expenses

Savings

Top spending category

Wallet Health Score trend

Users can export this report as a PDF or share it.

C. Savings Goal Tracker

Users create a savings goal.

Example:

Goal

New Laptop

Target

₱50,000

Current

₱18,500

37% Complete

Progress updates automatically when users record savings.

D. Quick Add Expense

A floating action button lets users quickly log an expense with minimal input, reducing friction and encouraging consistent tracking.

E. Favorite Transactions

Users can save frequently used transactions (for example, "Bus Fare ₱30" or "Lunch ₱120") and add them with one tap.

F. Financial Tips of the Day

A short tip displayed on the dashboard.

Examples:

"Cooking one extra meal at home this week can noticeably reduce food expenses."

"Review subscriptions monthly to avoid paying for services you no longer use."

"Setting aside a small amount after every payday can build an emergency fund over time."

    Notifications

The app can send reminders such as:

Record today's expenses

Budget nearly exceeded

New Wallet Health Score available

Monthly report is ready

Congratulations on maintaining your Essential Spending Streak

    Application Flow

Splash Screen

↓

Login / Register

↓

Home Dashboard

↓

Bottom Navigation

├── Dashboard ├── Transactions ├── Budgets ├── Analytics └── Profile

↓

Expense Details

↓

Wallet Health

↓

Reports

↓

Settings

    Database Structure (Example)

Users

userId

name

email

balance

walletHealthScore

streakDays

Expenses

expenseId

userId

amount

category

note

date

Income

incomeId

userId

amount

source

date

Budgets

budgetId

userId

category

limit

Categories

categoryId

userId

categoryName

isDefault

Savings Goals

goalId

userId

title

targetAmount

currentAmount

    Technology Stack

Frontend: Flutter (Dart)

Backend: Firebase

Authentication: Firebase Authentication

Database: Cloud Firestore

Notifications: Firebase Cloud Messaging (FCM)

Local Storage: SharedPreferences or Hive (for caching and offline support)

Charts: fl_chart

State Management: Provider or Riverpod (Provider is simpler for academic projects)

    What Makes Pockify Unique

Most expense trackers focus only on recording transactions. Pockify goes further by combining financial awareness, preventive budgeting, and habit-building into a simple, student-friendly application. Its standout features include the Smart Wallet Health Score, which translates spending behavior into an easy-to-understand daily score with actionable recommendations; Budget Buddy Alerts, which notify users before they exceed their budgets and provide practical cost-saving suggestions; and the Essential Spending Streak, a gamified system that rewards responsible spending on necessities rather than simply encouraging users to spend less. Together with customizable budgets, interactive analytics, savings goals, monthly reports, and quick expense logging, Pockify delivers a comprehensive yet lightweight personal finance experience that is feasible to develop in Flutter while offering meaningful value beyond a typical expense tracker.

for the app backend we plan on using supabase, so ignore the things say we're gonna use firebase and ignore anything that needs backend work, you can leave them with placeholders or just working front work, have a dashboard and everything essential for an expense tracker

for the design refer to the image and anything that requires backend work can be ignored and replaced with temporary things, make sure to refer to the image as a reference for the design but make it for an expense tracker thing complete with the mentioned features

This project was built with [Lovable](https://lovable.dev).

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/ebbe71a5-cef0-401f-b859-5c66ffb4e89a).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
#   P o c k i f y  
 