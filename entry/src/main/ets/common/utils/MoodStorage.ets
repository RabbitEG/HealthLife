/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 */

import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';

/** A journal record belonging to one calendar date. */
export class MoodRecord {
  mood: string = '';
  note: string = '';

  constructor(mood: string = '', note: string = '') {
    this.mood = mood;
    this.note = note;
  }
}

/**
 * Stores one mood and one short note per calendar date.
 *
 * Mood is deliberately kept outside taskInfo/dayInfo.  It is a journal
 * entry, not a task, so recording it must not change task progress or badge
 * calculations.
 */
export default class MoodStorage {
  private static readonly STORE_NAME: string = 'healthLifeMood';
  private static readonly KEY_MOODS: string = 'moodsByDate';

  static async load(context: common.UIAbilityContext, date: string): Promise<MoodRecord> {
    const store = await preferences.getPreferences(context, MoodStorage.STORE_NAME);
    const raw = await store.get(MoodStorage.KEY_MOODS, '{}');
    if (typeof raw !== 'string' || raw.length === 0) {
      return new MoodRecord();
    }
    try {
      const values = MoodStorage.parseValues(raw);
      return values[date] || new MoodRecord();
    } catch (error) {
      return new MoodRecord();
    }
  }

  static async loadAll(context: common.UIAbilityContext): Promise<Record<string, MoodRecord>> {
    const store = await preferences.getPreferences(context, MoodStorage.STORE_NAME);
    const raw = await store.get(MoodStorage.KEY_MOODS, '{}');
    if (typeof raw !== 'string' || raw.length === 0) {
      return {};
    }
    return MoodStorage.parseValues(raw);
  }

  static async save(context: common.UIAbilityContext, date: string, mood: string, note: string = ''): Promise<void> {
    const store = await preferences.getPreferences(context, MoodStorage.STORE_NAME);
    const raw = await store.get(MoodStorage.KEY_MOODS, '{}');
    let values: Record<string, MoodRecord> = {};
    if (typeof raw === 'string' && raw.length > 0) {
      try {
        values = MoodStorage.parseValues(raw);
      } catch (error) {
        values = {};
      }
    }
    values[date] = new MoodRecord(mood, note.trim());
    await store.put(MoodStorage.KEY_MOODS, JSON.stringify(values));
    await store.flush();
  }

  private static parseValues(raw: string): Record<string, MoodRecord> {
    const parsed = JSON.parse(raw) as Record<string, Object>;
    const values: Record<string, MoodRecord> = {};
    Object.keys(parsed).forEach((date: string) => {
      const value = parsed[date];
      // Keep records written by the first version (which stored only a
      // string mood) readable after notes were added.
      if (typeof value === 'string') {
        values[date] = new MoodRecord(value, '');
      } else if (value) {
        const record = value as Record<string, string>;
        values[date] = new MoodRecord(record.mood || '', record.note || '');
      }
    });
    return values;
  }
}
