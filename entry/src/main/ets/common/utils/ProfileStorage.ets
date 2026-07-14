/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0.
 */

import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import UserProfile from '../../model/UserProfile';

/** Local persistence for the profile editor. */
export default class ProfileStorage {
  private static readonly STORE_NAME: string = 'healthLifeProfile';
  private static readonly KEY_AVATAR: string = 'avatarUri';
  private static readonly KEY_AVATAR_ID: string = 'avatarId';
  private static readonly KEY_NICKNAME: string = 'nickname';
  private static readonly KEY_SIGNATURE: string = 'signature';
  private static readonly KEY_GENDER: string = 'gender';
  private static readonly KEY_BIRTH_DATE: string = 'birthDate';
  private static readonly KEY_HEIGHT: string = 'height';
  private static readonly KEY_WEIGHT: string = 'weight';

  static async load(context: common.UIAbilityContext): Promise<UserProfile> {
    const profile = new UserProfile();
    const store = await preferences.getPreferences(context, ProfileStorage.STORE_NAME);

    const avatar = await store.get(ProfileStorage.KEY_AVATAR, profile.avatarUri);
    const avatarId = await store.get(ProfileStorage.KEY_AVATAR_ID, profile.avatarId);
    const nickname = await store.get(ProfileStorage.KEY_NICKNAME, profile.nickname);
    const signature = await store.get(ProfileStorage.KEY_SIGNATURE, profile.signature);
    const gender = await store.get(ProfileStorage.KEY_GENDER, profile.gender);
    const birthDate = await store.get(ProfileStorage.KEY_BIRTH_DATE, profile.birthDate);
    const height = await store.get(ProfileStorage.KEY_HEIGHT, profile.height);
    const weight = await store.get(ProfileStorage.KEY_WEIGHT, profile.weight);

    if (typeof avatar === 'string') {
      profile.avatarUri = avatar;
    }
    if (typeof avatarId === 'string') {
      profile.avatarId = avatarId;
    }
    if (typeof nickname === 'string') {
      profile.nickname = nickname;
    }
    if (typeof signature === 'string') {
      profile.signature = signature;
    }
    if (typeof gender === 'string') {
      profile.gender = gender;
    }
    if (typeof birthDate === 'string') {
      profile.birthDate = birthDate;
    }
    if (typeof height === 'number') {
      profile.height = height;
    }
    if (typeof weight === 'number') {
      profile.weight = weight;
    }
    return profile;
  }

  static async save(context: common.UIAbilityContext, profile: UserProfile): Promise<void> {
    const store = await preferences.getPreferences(context, ProfileStorage.STORE_NAME);
    await store.put(ProfileStorage.KEY_AVATAR, profile.avatarUri);
    await store.put(ProfileStorage.KEY_AVATAR_ID, profile.avatarId);
    await store.put(ProfileStorage.KEY_NICKNAME, profile.nickname);
    await store.put(ProfileStorage.KEY_SIGNATURE, profile.signature);
    await store.put(ProfileStorage.KEY_GENDER, profile.gender);
    await store.put(ProfileStorage.KEY_BIRTH_DATE, profile.birthDate);
    await store.put(ProfileStorage.KEY_HEIGHT, profile.height);
    await store.put(ProfileStorage.KEY_WEIGHT, profile.weight);
    await store.flush();
  }
}
