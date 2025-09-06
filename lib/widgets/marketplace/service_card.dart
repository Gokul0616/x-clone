import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/service_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../media/fullscreen_image_viewer.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final bool showLikeButton;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.onLike,
    this.showLikeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service image
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: service.imageUrls.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullscreenImageViewer(
                                  imageUrls: service.imageUrls,
                                  heroTag: 'service_${service.id}',
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'service_${service.id}',
                            child: CachedNetworkImage(
                              imageUrl: service.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.work_outline,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.work_outline,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Service info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and like button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showLikeButton && onLike != null)
                          GestureDetector(
                            onTap: onLike,
                            child: Icon(
                              Icons.favorite_border,
                              size: 20,
                              color: theme.brightness == Brightness.dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      service.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Provider info
                    if (service.provider != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: service.provider!.profileImageUrl != null
                                ? NetworkImage(service.provider!.profileImageUrl!)
                                : null,
                            child: service.provider!.profileImageUrl == null
                                ? Text(
                                    service.provider!.displayName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              service.provider!.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (service.rating > 0) ...[
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${service.rating.toStringAsFixed(1)} (${service.reviewsCount})',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Bottom row: Price, location, delivery time
                    Row(
                      children: [
                        if (service.startingPrice != null) ...[
                          Text(
                            'From \$${service.startingPrice!.toStringAsFixed(0)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        Icon(
                          service.isRemote ? Icons.cloud_outlined : Icons.location_on_outlined,
                          size: 12,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            service.location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${service.deliveryDays} days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Skills/Tags
                    if (service.skills.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: service.skills.take(3).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}